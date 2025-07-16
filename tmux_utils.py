#!/usr/bin/env python3

import subprocess
import json
import time
import threading
import queue
from typing import List, Dict, Optional, Tuple
from dataclasses import dataclass
from datetime import datetime

@dataclass
class TmuxWindow:
    session_name: str
    window_index: int
    window_name: str
    active: bool
    
@dataclass
class TmuxSession:
    name: str
    windows: List[TmuxWindow]
    attached: bool

class TmuxError(Exception):
    """Base exception for tmux operations"""
    pass

class TmuxOrchestrator:
    def __init__(self, safety_mode: bool = True, cmd_timeout: int = 10):
        self._safety_mode = safety_mode  # Make immutable
        self.max_lines_capture = 1000
        self.CMD_TIMEOUT = cmd_timeout
        self.max_lines_per_pane = 20  # Conservative default
    
    @property
    def safety_mode(self) -> bool:
        """Read-only safety mode property"""
        return self._safety_mode
    
    def _safe_subprocess_large_output(self, cmd: List[str], timeout: int = None) -> Tuple[str, str, int]:
        """Safely run subprocess with large output handling to prevent deadlocks"""
        if timeout is None:
            timeout = self.CMD_TIMEOUT
            
        proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        try:
            stdout, stderr = proc.communicate(timeout=timeout)
            return stdout, stderr, proc.returncode
        except subprocess.TimeoutExpired:
            proc.kill()
            stdout, stderr = proc.communicate()  # Clean up
            raise TmuxError(f"Command timeout after {timeout}s: {cmd}")
    
    def _safe_subprocess_stream(self, cmd: List[str], timeout: int = None) -> str:
        """Stream subprocess output to prevent memory exhaustion"""
        if timeout is None:
            timeout = self.CMD_TIMEOUT
            
        proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        start_time = time.time()
        chunks = []
        
        try:
            for line in iter(proc.stdout.readline, ""):
                chunks.append(line)
                if time.time() - start_time > timeout:
                    proc.kill()
                    raise TmuxError(f"Command timeout after {timeout}s: {cmd}")
                
                # Memory safety: limit total size
                if len(chunks) > self.max_lines_capture:
                    break
                    
            proc.wait()
            return "".join(chunks)
        except Exception:
            proc.kill()
            raise
    
    def _safe_confirm(self, prompt: str, timeout: float = 5.0) -> bool:
        """Cross-platform safe confirmation with timeout"""
        result_queue = queue.Queue()
        
        def get_input():
            try:
                response = input(prompt)
                result_queue.put(response.strip().lower())
            except EOFError:
                result_queue.put("")
        
        thread = threading.Thread(target=get_input)
        thread.daemon = True
        thread.start()
        
        try:
            response = result_queue.get(timeout=timeout)
            return response == "yes"
        except queue.Empty:
            return False
        
    def get_tmux_sessions(self) -> List[TmuxSession]:
        """Get all tmux sessions and their windows with batched queries"""
        try:
            # Get sessions
            sessions_cmd = ["tmux", "list-sessions", "-F", "#{session_name}:#{session_attached}"]
            sessions_stdout, sessions_stderr, return_code = self._safe_subprocess_large_output(sessions_cmd)
            if return_code != 0:
                raise TmuxError(f"Failed to get sessions: {sessions_stderr}")
            
            # Batch query all windows across all sessions
            windows_cmd = [
                "tmux", "list-windows", "-a", 
                "-F", "#{session_name}:#{window_index}:#{window_name}:#{window_active}"
            ]
            windows_stdout, windows_stderr, return_code = self._safe_subprocess_large_output(windows_cmd)
            if return_code != 0:
                raise TmuxError(f"Failed to get all windows: {windows_stderr}")
            
            # Parse sessions
            session_data = {}
            for line in sessions_stdout.strip().split('\n'):
                if not line:
                    continue
                session_name, attached = line.split(':')
                session_data[session_name] = {
                    'attached': attached == '1',
                    'windows': []
                }
            
            # Parse and group windows by session
            for window_line in windows_stdout.strip().split('\n'):
                if not window_line:
                    continue
                parts = window_line.split(':')
                if len(parts) >= 4:
                    session_name, window_index, window_name, window_active = parts[0], parts[1], parts[2], parts[3]
                    if session_name in session_data:
                        session_data[session_name]['windows'].append(TmuxWindow(
                            session_name=session_name,
                            window_index=int(window_index),
                            window_name=window_name,
                            active=window_active == '1'
                        ))
            
            # Build session objects
            sessions = []
            for session_name, data in session_data.items():
                sessions.append(TmuxSession(
                    name=session_name,
                    windows=data['windows'],
                    attached=data['attached']
                ))
            
            return sessions
        except (subprocess.CalledProcessError, TmuxError) as e:
            raise TmuxError(f"Error getting tmux sessions: {e}") from e
    
    def capture_window_content(self, session_name: str, window_index: int, num_lines: int = 50) -> str:
        """Safely capture the last N lines from a tmux window with streaming"""
        if num_lines > self.max_lines_capture:
            num_lines = self.max_lines_capture
            
        try:
            cmd = ["tmux", "capture-pane", "-t", f"{session_name}:{window_index}", "-p", "-S", f"-{num_lines}"]
            
            # Use streaming for large captures
            if num_lines > 100:
                return self._safe_subprocess_stream(cmd)
            else:
                stdout, stderr, return_code = self._safe_subprocess_large_output(cmd)
                if return_code != 0:
                    raise TmuxError(f"Failed to capture window content: {stderr}")
                return stdout
        except (subprocess.CalledProcessError, TmuxError) as e:
            raise TmuxError(f"Error capturing window content: {e}") from e
    
    def get_window_info(self, session_name: str, window_index: int) -> Dict:
        """Get detailed information about a specific window"""
        try:
            cmd = ["tmux", "display-message", "-t", f"{session_name}:{window_index}", "-p", 
                   "#{window_name}:#{window_active}:#{window_panes}:#{window_layout}"]
            stdout, stderr, return_code = self._safe_subprocess_large_output(cmd)
            
            if return_code != 0:
                raise TmuxError(f"Failed to get window info: {stderr}")
            
            if stdout.strip():
                parts = stdout.strip().split(':')
                return {
                    "name": parts[0],
                    "active": parts[1] == '1',
                    "panes": int(parts[2]),
                    "layout": parts[3],
                    "content": self.capture_window_content(session_name, window_index)
                }
        except (subprocess.CalledProcessError, TmuxError) as e:
            raise TmuxError(f"Could not get window info: {e}") from e
    
    def send_keys_to_window(self, session_name: str, window_index: int, keys: str, confirm: bool = True) -> bool:
        """Safely send keys to a tmux window with confirmation"""
        if self.safety_mode and confirm:
            prompt = f"SAFETY CHECK: About to send '{keys}' to {session_name}:{window_index}\nConfirm? (yes/no): "
            if not self._safe_confirm(prompt):
                print("Operation cancelled")
                return False
        
        try:
            # Escape special characters to prevent command injection
            safe_keys = keys.replace(";", r"\;").replace("$", r"\$").replace("`", r"\`")
            cmd = ["tmux", "send-keys", "-l", "-t", f"{session_name}:{window_index}", safe_keys]
            stdout, stderr, return_code = self._safe_subprocess_large_output(cmd)
            if return_code != 0:
                raise TmuxError(f"Failed to send keys: {stderr}")
            return True
        except (subprocess.CalledProcessError, TmuxError) as e:
            raise TmuxError(f"Error sending keys: {e}") from e
    
    def send_command_to_window(self, session_name: str, window_index: int, command: str, confirm: bool = True) -> bool:
        """Send a command to a window (adds Enter automatically)"""
        # First send the command text
        if not self.send_keys_to_window(session_name, window_index, command, confirm):
            return False
        # Then send the actual Enter key (C-m)
        try:
            cmd = ["tmux", "send-keys", "-t", f"{session_name}:{window_index}", "C-m"]
            stdout, stderr, return_code = self._safe_subprocess_large_output(cmd)
            if return_code != 0:
                raise TmuxError(f"Failed to send Enter key: {stderr}")
            return True
        except (subprocess.CalledProcessError, TmuxError) as e:
            raise TmuxError(f"Error sending Enter key: {e}") from e
    
    def get_all_windows_status(self) -> Dict:
        """Get status of all windows across all sessions"""
        sessions = self.get_tmux_sessions()
        status = {
            "timestamp": datetime.now().isoformat(),
            "sessions": []
        }
        
        for session in sessions:
            session_data = {
                "name": session.name,
                "attached": session.attached,
                "windows": []
            }
            
            for window in session.windows:
                window_info = self.get_window_info(session.name, window.window_index)
                window_data = {
                    "index": window.window_index,
                    "name": window.window_name,
                    "active": window.active,
                    "info": window_info
                }
                session_data["windows"].append(window_data)
            
            status["sessions"].append(session_data)
        
        return status
    
    def find_window_by_name(self, window_name: str) -> List[Tuple[str, int]]:
        """Find windows by name across all sessions"""
        sessions = self.get_tmux_sessions()
        matches = []
        
        for session in sessions:
            for window in session.windows:
                if window_name.lower() in window.window_name.lower():
                    matches.append((session.name, window.window_index))
        
        return matches
    
    def create_monitoring_snapshot(self) -> str:
        """Create a comprehensive snapshot for Claude analysis"""
        status = self.get_all_windows_status()
        
        # Format for Claude consumption
        snapshot = f"Tmux Monitoring Snapshot - {status['timestamp']}\n"
        snapshot += "=" * 50 + "\n\n"
        
        for session in status['sessions']:
            snapshot += f"Session: {session['name']} ({'ATTACHED' if session['attached'] else 'DETACHED'})\n"
            snapshot += "-" * 30 + "\n"
            
            for window in session['windows']:
                snapshot += f"  Window {window['index']}: {window['name']}"
                if window['active']:
                    snapshot += " (ACTIVE)"
                snapshot += "\n"
                
                if 'content' in window['info']:
                    # Get last 10 lines for overview
                    content_lines = window['info']['content'].split('\n')
                    recent_lines = content_lines[-10:] if len(content_lines) > 10 else content_lines
                    snapshot += "    Recent output:\n"
                    for line in recent_lines:
                        if line.strip():
                            snapshot += f"    | {line}\n"
                snapshot += "\n"
        
        return snapshot

if __name__ == "__main__":
    orchestrator = TmuxOrchestrator()
    status = orchestrator.get_all_windows_status()
    print(json.dumps(status, indent=2))