#!/bin/bash
# Claude Friends Templates Setup Script
# This script automates the initial setup of a new project using Claude Friends Templates

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Print colored message
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Welcome message
echo ""
echo -e "${GREEN}🚀 Claude Friends Templates Setup${NC}"
echo "=================================="
echo ""

# Check if we're in the claude-friends-templates directory
if [ ! -f "CLAUDE.md" ] || [ ! -d ".claude" ]; then
    print_error "This script must be run from the claude-friends-templates directory."
    exit 1
fi

# Get project name
read -p "Enter your project name: " PROJECT_NAME
if [ -z "$PROJECT_NAME" ]; then
    print_error "Project name cannot be empty."
    exit 1
fi

# Get project description
read -p "Enter a brief project description: " PROJECT_DESC
if [ -z "$PROJECT_DESC" ]; then
    PROJECT_DESC="A project built with Claude Friends Templates"
fi

# Choose language
echo ""
echo "Choose your preferred language:"
echo "1) English (default)"
echo "2) Japanese (日本語)"
read -p "Enter your choice [1-2]: " LANG_CHOICE

# Set language flag
USE_JAPANESE=false
if [ "$LANG_CHOICE" == "2" ]; then
    USE_JAPANESE=true
    print_info "Japanese version will be set as default."
fi

# Update CLAUDE.md
print_info "Updating CLAUDE.md..."
if [ "$USE_JAPANESE" == true ] && [ -f "CLAUDE_ja.md" ]; then
    # Use Japanese version
    mv CLAUDE.md CLAUDE_en.md
    cp CLAUDE_ja.md CLAUDE.md
fi

# Replace placeholders in CLAUDE.md
sed -i.bak "s/\[Project Name\]/$PROJECT_NAME/g" CLAUDE.md
sed -i.bak "s/\[Write a concise description of the project here\]/$PROJECT_DESC/g" CLAUDE.md
sed -i.bak "s/\[プロジェクトの説明を書く...\]/$PROJECT_DESC/g" CLAUDE.md
rm -f CLAUDE.md.bak

# Update README files
if [ "$USE_JAPANESE" == true ]; then
    print_info "Setting Japanese as default language..."
    if [ -f "README_ja.md" ]; then
        mv README.md README_en.md
        mv README_ja.md README.md
        print_success "Japanese README set as default."
    fi
    
    if [ -f ".clauderules_ja" ]; then
        mv .clauderules .clauderules_en
        mv .clauderules_ja .clauderules
        print_success "Japanese .clauderules set as default."
    fi
fi

# Initialize git repository
if [ -d ".git" ]; then
    print_warning "Git repository already exists. Skipping git init."
else
    print_info "Initializing new git repository..."
    git init
    print_success "Git repository initialized."
fi

# Make scripts executable
print_info "Setting executable permissions on scripts..."
chmod +x .claude/scripts/*.sh 2>/dev/null || true
chmod +x .claude/scripts/*.py 2>/dev/null || true

# Create initial .gitignore if it doesn't exist
if [ ! -f ".gitignore" ]; then
    print_info "Creating .gitignore..."
    cat > .gitignore << 'EOF'
# Claude Code cache
.ccache/
*.cache

# OS files
.DS_Store
*.swp
*.tmp

# Environment files
.env
.env.local

# IDE files
.vscode/settings.json
.idea/

# Logs
*.log
logs/

# Dependencies
node_modules/
venv/
__pycache__/
*.pyc

# Build files
dist/
build/
*.egg-info/

# Test coverage
coverage/
.coverage
htmlcov/
EOF
    print_success ".gitignore created."
fi

# Create a sample .env.example file
if [ ! -f ".env.example" ]; then
    print_info "Creating .env.example..."
    cat > .env.example << 'EOF'
# Example environment variables
# Copy this file to .env and fill in your values

# API Keys
# API_KEY=your_api_key_here

# Database
# DATABASE_URL=postgresql://user:password@localhost:5432/dbname

# Environment
# NODE_ENV=development
EOF
    print_success ".env.example created."
fi

# Summary
echo ""
echo -e "${GREEN}✅ Setup Complete!${NC}"
echo "=================="
echo ""
echo "Project Name: $PROJECT_NAME"
echo "Description: $PROJECT_DESC"
echo "Language: $([ "$USE_JAPANESE" == true ] && echo "Japanese" || echo "English")"
echo ""
echo "Next steps:"
echo "1. Review and customize CLAUDE.md for your specific needs"
echo "2. Start with the Planner agent: /agent:planner"
echo "3. Follow the 3-phase development flow:"
echo "   - Requirements → Design → Implementation"
echo ""
echo "For detailed guidance, see:"
if [ "$USE_JAPANESE" == true ]; then
    echo "- Quick Start: README.md (日本語版)"
    echo "- User Guide: .claude/claude-friends-guide_ja.md"
else
    echo "- Quick Start: README.md"
    echo "- User Guide: .claude/claude-friends-guide.md"
fi
echo ""
echo "Happy coding with Claude Friends! 🎉"