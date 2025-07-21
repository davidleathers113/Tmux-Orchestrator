#!/bin/bash
# Setup script for DCE Whiteboard orchestration with PM oversight

set -euo pipefail

# Configuration
PROJECT_DIR="/Users/davidleathers/dce-whiteboard"
ORCHESTRATOR_DIR="/Users/davidleathers/projects/Tmux-Orchestrator"
SPEC_TEMPLATE="${PROJECT_DIR}/.claude/templates/project-spec-template.md"

echo "🚀 DCE Whiteboard Orchestrator Setup"
echo "===================================="
echo ""

# Step 1: Verify prerequisites
echo "Step 1: Verifying prerequisites..."

if ! command -v tmux &> /dev/null; then
    echo "❌ tmux is not installed. Please install with: brew install tmux"
    exit 1
fi

if [ ! -d "$PROJECT_DIR" ]; then
    echo "❌ DCE Whiteboard project not found at: $PROJECT_DIR"
    exit 1
fi

if [ ! -d "$ORCHESTRATOR_DIR" ]; then
    echo "❌ Tmux Orchestrator not found at: $ORCHESTRATOR_DIR"
    exit 1
fi

echo "✅ All prerequisites met"
echo ""

# Step 2: Create tmux sessions
echo "Step 2: Creating tmux sessions..."

# Kill existing sessions if they exist
tmux kill-session -t dce-engineer 2>/dev/null || true
tmux kill-session -t dce-pm 2>/dev/null || true
tmux kill-session -t dce-server 2>/dev/null || true
tmux kill-session -t orchestrator 2>/dev/null || true

# Create new sessions
tmux new-session -s dce-engineer -c "$PROJECT_DIR" -d
echo "✅ Created dce-engineer session"

tmux new-session -s dce-pm -c "$PROJECT_DIR" -d
echo "✅ Created dce-pm session (optional, for PM agent)"

tmux new-session -s dce-server -c "$PROJECT_DIR" -d
echo "✅ Created dce-server session (for dev server)"

# Create orchestrator session in the orchestrator directory (where scripts are)
tmux new-session -s orchestrator -c "$ORCHESTRATOR_DIR" -d
echo "✅ Created orchestrator session"

echo ""
echo "Sessions created:"
tmux list-sessions | grep -E "(dce-|orchestrator)"
echo ""

# Step 3: Generate project spec
echo "Step 3: Preparing project specification..."

# Check if spec template exists
if [ ! -f "$SPEC_TEMPLATE" ]; then
    echo "⚠️  No spec template found. You'll need to create one."
    echo "   Run this in the dce-engineer session:"
    echo "   /project:analyze-project"
    echo ""
else
    echo "✅ Spec template found at: $SPEC_TEMPLATE"
fi

# Create a starter spec if needed
SPEC_FILE="$HOME/dce-whiteboard-spec.md"
if [ ! -f "$SPEC_FILE" ]; then
    echo "📝 Creating starter spec at: $SPEC_FILE"
    cat > "$SPEC_FILE" << 'EOF'
# DCE Whiteboard Project Specification

## PROJECT: DCE Whiteboard Development
## GOAL: [To be filled by project analysis]

## CONSTRAINTS:
- Use existing codebase at /Users/davidleathers/dce-whiteboard/
- Follow existing code patterns and conventions
- Commit changes every 30 minutes
- Run tests before committing
- Maintain clean git history
- Follow DCE Whiteboard CLAUDE.md guidelines

## DELIVERABLES:
[To be determined by project analysis]
1. Run /project:analyze-project to identify current state
2. Specific deliverables will be added based on analysis

## SUCCESS CRITERIA:
- All tests pass
- Code follows project conventions
- Features work as specified
- No regressions introduced
- Clean commits with descriptive messages
- Performance targets met (<500KB bundle, 60fps canvas)

## TECHNICAL DETAILS:
- Project path: /Users/davidleathers/dce-whiteboard/
- Stack: Next.js 15.3, React 19.1, TypeScript 5.8, Supabase 2.50
- Performance targets from CLAUDE.md enforced
EOF
    echo "✅ Starter spec created"
else
    echo "✅ Spec already exists at: $SPEC_FILE"
fi

echo ""

# Step 4: Setup instructions
echo "Step 4: Next Steps"
echo "=================="
echo ""
echo "1. ANALYZE THE PROJECT (Recommended first step):"
echo "   tmux attach -t dce-engineer"
echo "   claude"
echo "   /project:analyze-project"
echo "   # This will generate a detailed spec based on actual code"
echo ""
echo "2. START THE ORCHESTRATOR:"
echo "   tmux attach -t orchestrator"
echo "   claude"
echo "   # If you ran analyze-project, use the generated spec:"
echo "   /pm-oversight dce-engineer SPEC: /Users/davidleathers/dce-whiteboard/.claude/specs/project-spec-[timestamp].md"
echo "   # Or use the starter spec:"
echo "   /pm-oversight dce-engineer SPEC: ~/dce-whiteboard-spec.md"
echo ""
echo "3. OPTIONAL - START DEV SERVER:"
echo "   tmux attach -t dce-server"
echo "   cd $PROJECT_DIR"
echo "   npm run dev"
echo ""
echo "4. MONITOR ACTIVITY:"
echo "   # In a new terminal:"
echo "   cd $ORCHESTRATOR_DIR"
echo "   ./monitor-dce.sh"
echo ""
echo "IMPORTANT NOTES:"
echo "- The orchestrator must run from: $ORCHESTRATOR_DIR"
echo "- This is where the scheduling scripts are located"
echo "- The PM will coordinate work in the dce-engineer session"
echo "- Check-ins will be scheduled automatically"
echo ""
echo "✅ Setup complete! Ready for DCE Whiteboard orchestration."