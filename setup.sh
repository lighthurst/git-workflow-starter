#!/bin/bash

# Git Workflow Starter - Interactive Setup
# Usage: ./setup.sh /path/to/your/project

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${1:-.}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Git Workflow Starter${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Validate target directory
if [[ "$TARGET_DIR" != "." ]] && [[ ! -d "$TARGET_DIR" ]]; then
    echo -e "${RED}Error: Directory '$TARGET_DIR' does not exist${NC}"
    exit 1
fi

TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"
echo -e "Target: ${GREEN}$TARGET_DIR${NC}"
echo ""

# Step 1: Choose hook framework
echo -e "${YELLOW}[1/2] Choose your git hooks framework:${NC}"
echo ""
echo "  1) Husky (Node.js)"
echo "     - Standard in JS ecosystem"
echo "     - Uses npm for everything"
echo ""
echo "  2) Pre-commit (Python)"
echo "     - Better for Terraform/Go/Python/polyglot"
echo "     - Huge hook ecosystem"
echo "     - Still uses npm for semantic-release only"
echo ""
echo "  3) Rust-native"
echo "     - Zero Node.js/Python dependencies"
echo "     - Uses cargo-husky for hooks"
echo "     - Uses release-plz for releases"
echo ""
read -p "Enter choice [1-3]: " HOOK_CHOICE

case $HOOK_CHOICE in
    1) FRAMEWORK="husky" ;;
    2) FRAMEWORK="pre-commit" ;;
    3) FRAMEWORK="rust-native" ;;
    *) echo -e "${RED}Invalid choice${NC}"; exit 1 ;;
esac

echo ""

# Step 2: Choose project type (for pre-commit only)
if [[ "$FRAMEWORK" == "pre-commit" ]]; then
    echo -e "${YELLOW}[2/2] What type of project?${NC}"
    echo ""
    echo "  1) Terraform / Infrastructure"
    echo "  2) JavaScript / TypeScript"
    echo "  3) Python"
    echo "  4) Go"
    echo "  5) Generic (just basics)"
    echo ""
    read -p "Enter choice [1-5]: " PROJECT_TYPE
elif [[ "$FRAMEWORK" == "rust-native" ]]; then
    echo -e "${YELLOW}[2/2] Rust-native selected - copying files...${NC}"
    PROJECT_TYPE="na"
else
    echo -e "${YELLOW}[2/2] Husky selected - copying files...${NC}"
    PROJECT_TYPE="na"
fi

echo ""
echo -e "${BLUE}Setting up $FRAMEWORK workflow...${NC}"
echo ""

# Create directories
mkdir -p "$TARGET_DIR/.github/workflows"

# Copy shared files (for husky and pre-commit, NOT rust-native)
if [[ "$FRAMEWORK" != "rust-native" ]]; then
    cp "$SCRIPT_DIR/shared/.releaserc.json" "$TARGET_DIR/"
    cp "$SCRIPT_DIR/shared/commitlint.config.js" "$TARGET_DIR/"
    cp "$SCRIPT_DIR/shared/.nvmrc" "$TARGET_DIR/"
    cp "$SCRIPT_DIR/shared/.github/workflows/ci.yml" "$TARGET_DIR/.github/workflows/"
fi

# Copy GitHub templates (used by all approaches)
cp "$SCRIPT_DIR/shared/.github/dependabot.yml" "$TARGET_DIR/.github/"
cp "$SCRIPT_DIR/shared/.github/pull_request_template.md" "$TARGET_DIR/.github/"

if [[ "$FRAMEWORK" == "husky" ]]; then
    # Copy Husky files
    cp "$SCRIPT_DIR/husky/package.json" "$TARGET_DIR/"
    mkdir -p "$TARGET_DIR/.husky"
    cp "$SCRIPT_DIR/husky/.husky/commit-msg" "$TARGET_DIR/.husky/"
    cp "$SCRIPT_DIR/husky/.husky/pre-commit" "$TARGET_DIR/.husky/"
    chmod +x "$TARGET_DIR/.husky/commit-msg" "$TARGET_DIR/.husky/pre-commit"

    echo -e "${GREEN}Files copied!${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "  cd $TARGET_DIR"
    echo "  npm install"
    echo "  # Edit .husky/pre-commit to add your checks"
    echo ""

elif [[ "$FRAMEWORK" == "rust-native" ]]; then
    # Copy rust-native files
    cp "$SCRIPT_DIR/rust-native/.github/workflows/ci.yml" "$TARGET_DIR/.github/workflows/"
    cp "$SCRIPT_DIR/rust-native/release-plz.toml" "$TARGET_DIR/"
    cp "$SCRIPT_DIR/rust-native/committed.toml" "$TARGET_DIR/"
    cp "$SCRIPT_DIR/rust-native/.gitignore" "$TARGET_DIR/"
    cp "$SCRIPT_DIR/rust-native/Cargo.toml.template" "$TARGET_DIR/"

    # Copy cargo-husky hooks
    mkdir -p "$TARGET_DIR/.cargo-husky/hooks"
    cp "$SCRIPT_DIR/rust-native/.cargo-husky/hooks/pre-commit" "$TARGET_DIR/.cargo-husky/hooks/"
    cp "$SCRIPT_DIR/rust-native/.cargo-husky/hooks/commit-msg" "$TARGET_DIR/.cargo-husky/hooks/"
    chmod +x "$TARGET_DIR/.cargo-husky/hooks/pre-commit" "$TARGET_DIR/.cargo-husky/hooks/commit-msg"

    # Update dependabot for cargo
    sed -i.bak 's/package-ecosystem: "npm"/package-ecosystem: "cargo"/' "$TARGET_DIR/.github/dependabot.yml"
    rm -f "$TARGET_DIR/.github/dependabot.yml.bak"

    echo -e "${GREEN}Files copied!${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "  cd $TARGET_DIR"
    echo "  # Review Cargo.toml.template and merge into your Cargo.toml"
    echo "  cargo install committed  # for local commit validation"
    echo "  cargo test  # installs git hooks via cargo-husky"
    echo ""
    echo -e "${YELLOW}Key files:${NC}"
    echo "  - Cargo.toml.template: Shows how to configure cargo-husky"
    echo "  - .cargo-husky/hooks/: Git hook scripts (pre-commit, commit-msg)"
    echo "  - committed.toml: Conventional commit rules"
    echo "  - release-plz.toml: Release automation config"
    echo ""

else
    # Copy pre-commit files
    cp "$SCRIPT_DIR/pre-commit/package.json" "$TARGET_DIR/"
    cp "$SCRIPT_DIR/pre-commit/.pre-commit-config.yaml" "$TARGET_DIR/"

    # Uncomment relevant hooks based on project type
    case $PROJECT_TYPE in
        1) # Terraform
            sed -i.bak '/# TERRAFORM HOOKS/,/^$/s/^  # /  /' "$TARGET_DIR/.pre-commit-config.yaml"
            rm -f "$TARGET_DIR/.pre-commit-config.yaml.bak"
            echo -e "${GREEN}Enabled Terraform hooks (fmt, validate, tflint)${NC}"
            ;;
        2) # JavaScript
            sed -i.bak '/# JAVASCRIPT/,/^$/s/^  # /  /' "$TARGET_DIR/.pre-commit-config.yaml"
            rm -f "$TARGET_DIR/.pre-commit-config.yaml.bak"
            echo -e "${GREEN}Enabled JavaScript hooks (eslint, prettier)${NC}"
            ;;
        3) # Python
            sed -i.bak '/# PYTHON HOOKS/,/^$/s/^  # /  /' "$TARGET_DIR/.pre-commit-config.yaml"
            rm -f "$TARGET_DIR/.pre-commit-config.yaml.bak"
            echo -e "${GREEN}Enabled Python hooks (ruff, mypy)${NC}"
            ;;
        4) # Go
            sed -i.bak '/# GO HOOKS/,/^$/s/^  # /  /' "$TARGET_DIR/.pre-commit-config.yaml"
            rm -f "$TARGET_DIR/.pre-commit-config.yaml.bak"
            echo -e "${GREEN}Enabled Go hooks (fmt, vet, build)${NC}"
            ;;
        5) # Generic
            echo -e "${GREEN}Using generic hooks only${NC}"
            ;;
    esac

    echo ""
    echo -e "${GREEN}Files copied!${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "  cd $TARGET_DIR"
    echo "  pip install pre-commit"
    echo "  pre-commit install"
    echo "  pre-commit install --hook-type commit-msg"
    echo "  npm install  # for semantic-release"
    echo ""
fi

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Done!${NC} Your git workflow is ready."
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
