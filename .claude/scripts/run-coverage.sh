#!/bin/bash
# Coverage test runner script
# Provides easy access to different coverage reporting options

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧪 Claude Friends Templates - Coverage Test Runner${NC}"
echo "=================================================="

# Change to project root
cd "$PROJECT_ROOT"

# Function to display usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -q, --quick    Run tests with minimal coverage report"
    echo "  -f, --full     Run tests with full coverage report (default)"
    echo "  -o, --open     Open HTML coverage report in browser after running"
    echo "  -c, --clean    Clean previous coverage data before running"
    echo "  --html-only    Generate only HTML report"
    echo "  --term-only    Show only terminal report"
    echo ""
    echo "Examples:"
    echo "  $0                 # Run full coverage with all reports"
    echo "  $0 --quick        # Quick run with basic terminal output"
    echo "  $0 --open         # Run coverage and open HTML report"
    echo "  $0 --clean        # Clean and run fresh coverage"
}

# Default options
QUICK_MODE=false
OPEN_BROWSER=false
CLEAN_FIRST=false
HTML_ONLY=false
TERM_ONLY=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -q|--quick)
            QUICK_MODE=true
            shift
            ;;
        -f|--full)
            QUICK_MODE=false
            shift
            ;;
        -o|--open)
            OPEN_BROWSER=true
            shift
            ;;
        -c|--clean)
            CLEAN_FIRST=true
            shift
            ;;
        --html-only)
            HTML_ONLY=true
            shift
            ;;
        --term-only)
            TERM_ONLY=true
            shift
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            usage
            exit 1
            ;;
    esac
done

# Clean previous coverage data if requested
if [[ "$CLEAN_FIRST" == true ]]; then
    echo -e "${YELLOW}🧹 Cleaning previous coverage data...${NC}"
    rm -rf htmlcov/ .coverage coverage.xml coverage.json
    echo "✓ Coverage data cleaned"
    echo ""
fi

# Determine pytest options based on mode
if [[ "$QUICK_MODE" == true ]]; then
    echo -e "${YELLOW}⚡ Running quick coverage test...${NC}"
    PYTEST_OPTS="--cov=.claude --cov-report=term-missing --tb=short"
elif [[ "$HTML_ONLY" == true ]]; then
    echo -e "${BLUE}📊 Generating HTML coverage report only...${NC}"
    PYTEST_OPTS="--cov=.claude --cov-report=html --tb=short"
elif [[ "$TERM_ONLY" == true ]]; then
    echo -e "${GREEN}📋 Terminal coverage report only...${NC}"
    PYTEST_OPTS="--cov=.claude --cov-report=term-missing --tb=short"
else
    echo -e "${GREEN}🔍 Running full coverage analysis...${NC}"
    PYTEST_OPTS="--cov=.claude --cov-report=html --cov-report=term-missing --cov-report=xml --cov-report=json --tb=short"
fi

# Run the tests with coverage
echo "Running: python -m pytest $PYTEST_OPTS"
echo ""

if python -m pytest $PYTEST_OPTS; then
    echo ""
    echo -e "${GREEN}✅ Tests completed successfully!${NC}"

    # Show coverage summary
    if [[ -f ".coverage" ]]; then
        echo ""
        echo -e "${BLUE}📈 Coverage Summary:${NC}"
        python -m coverage report --show-missing --skip-covered
    fi

    # Open browser if requested and HTML report exists
    if [[ "$OPEN_BROWSER" == true ]] && [[ -d "htmlcov" ]]; then
        echo ""
        echo -e "${BLUE}🌐 Opening HTML coverage report...${NC}"
        if command -v xdg-open > /dev/null; then
            xdg-open htmlcov/index.html
        elif command -v open > /dev/null; then
            open htmlcov/index.html
        else
            echo -e "${YELLOW}⚠️  Could not open browser automatically${NC}"
            echo "HTML report available at: htmlcov/index.html"
        fi
    fi

    # Show report locations
    echo ""
    echo -e "${BLUE}📂 Report Locations:${NC}"
    [[ -d "htmlcov" ]] && echo "  HTML: htmlcov/index.html"
    [[ -f "coverage.xml" ]] && echo "  XML:  coverage.xml"
    [[ -f "coverage.json" ]] && echo "  JSON: coverage.json"

else
    echo ""
    echo -e "${RED}❌ Tests failed or coverage threshold not met${NC}"
    exit 1
fi