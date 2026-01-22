#!/bin/bash

# Cursor Window Activator - Installation Script
# Cross-platform installation script for Cursor hooks
# Can be run directly via curl or from cloned repository

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Detect OS
detect_os() {
    case "$(uname -s)" in
        Darwin*)
            echo "macos"
            ;;
        Linux*)
            echo "linux"
            ;;
        MINGW*|MSYS*|CYGWIN*)
            echo "windows"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Print colored message
print_message() {
    local color=$1
    shift
    echo -e "${color}$@${NC}"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install dependencies for Linux
install_linux_dependencies() {
    if command_exists xdotool; then
        print_message "$GREEN" "✓ xdotool is already installed"
        return 0
    fi
    
    if command_exists wmctrl; then
        print_message "$GREEN" "✓ wmctrl is already installed"
        return 0
    fi
    
    print_message "$YELLOW" "⚠ xdotool or wmctrl is required for Linux"
    
    if command_exists apt-get; then
        print_message "$YELLOW" "Installing xdotool via apt-get..."
        sudo apt-get update && sudo apt-get install -y xdotool
    elif command_exists yum; then
        print_message "$YELLOW" "Installing xdotool via yum..."
        sudo yum install -y xdotool
    elif command_exists dnf; then
        print_message "$YELLOW" "Installing xdotool via dnf..."
        sudo dnf install -y xdotool
    elif command_exists pacman; then
        print_message "$YELLOW" "Installing xdotool via pacman..."
        sudo pacman -S --noconfirm xdotool
    else
        print_message "$RED" "✗ Could not detect package manager. Please install xdotool manually:"
        print_message "$YELLOW" "  sudo apt-get install xdotool  # Debian/Ubuntu"
        print_message "$YELLOW" "  sudo yum install xdotool      # CentOS/RHEL"
        print_message "$YELLOW" "  sudo pacman -S xdotool        # Arch Linux"
        return 1
    fi
}

# Update hooks.json to add our hooks
update_hooks_json() {
    local hooks_json="$1"
    local script_path="$2"
    
    # Check if hooks already exist
    if [ -f "$hooks_json" ] && grep -q "activate-window.sh" "$hooks_json"; then
        print_message "$GREEN" "✓ Hooks for activate-window.sh already exist in hooks.json"
        return 0
    fi
    
    # Check if jq is available for JSON manipulation
    if command_exists jq; then
        # Use jq to merge hooks
        local temp_file=$(mktemp)
        local output_file=$(mktemp)
        
        # Read existing hooks.json
        if [ -f "$hooks_json" ] && [ -s "$hooks_json" ]; then
            cp "$hooks_json" "$temp_file"
        else
            echo '{"version":1,"hooks":{}}' > "$temp_file"
        fi
        
        # Add our hooks using jq - check if hook arrays exist, if not create them
        if jq --arg script "$script_path" '
            .version = (.version // 1) |
            .hooks = (.hooks // {}) |
            .hooks.beforeSubmitPrompt = ((.hooks.beforeSubmitPrompt // []) | if map(.command) | index($script) then . else . + [{"command": $script}] end) |
            .hooks.afterAgentResponse = ((.hooks.afterAgentResponse // []) | if map(.command) | index($script) then . else . + [{"command": $script}] end)
        ' "$temp_file" > "$output_file" 2>/dev/null; then
            # Check if output is not empty and valid JSON
            if [ -s "$output_file" ] && jq empty "$output_file" 2>/dev/null; then
                # Create backup before overwriting
                if [ -f "$hooks_json" ]; then
                    cp "$hooks_json" "$hooks_json.backup"
                fi
                mv "$output_file" "$hooks_json"
                rm -f "$temp_file"
                return 0
            else
                print_message "$RED" "✗ jq produced invalid or empty output"
                rm -f "$temp_file" "$output_file"
                return 1
            fi
        else
            print_message "$RED" "✗ jq failed to update hooks.json"
            rm -f "$temp_file" "$output_file"
            return 1
        fi
    fi
    
    # Fallback: manual JSON parsing (simple approach)
    if [ -f "$hooks_json" ] && [ -s "$hooks_json" ]; then
        print_message "$YELLOW" "⚠ jq not found. Cannot safely update hooks.json automatically."
        print_message "$YELLOW" "  Please manually add the following to your hooks.json:"
        print_message "$YELLOW" "  - beforeSubmitPrompt: $script_path"
        print_message "$YELLOW" "  - afterAgentResponse: $script_path"
        print_message "$YELLOW" "  See hooks.json.example for reference."
    fi
    
    return 1
}

# Get script directory or download from GitHub
get_script_dir() {
    # Try to get the directory where the script is located
    if [ -L "$0" ]; then
        # If script is a symlink, resolve it
        SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
    else
        SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
    fi
    
    # Check if we're running from a cloned repo (activate-window.sh exists)
    if [ -f "$SCRIPT_DIR/activate-window.sh" ]; then
        echo "$SCRIPT_DIR"
        return 0
    fi
    
    # If not, we're running via curl - download files to temp directory
    TEMP_DIR=$(mktemp -d)
пые    GITHUB_REPO="beautyfree/cursor-window-activate-hook"
    GITHUB_BRANCH="main"
    
    print_message "$YELLOW" "📥 Downloading files from GitHub..."
    
    # Download activate-window.sh
    if command_exists curl; then
        curl -fsSL "https://raw.githubusercontent.com/$GITHUB_REPO/$GITHUB_BRANCH/activate-window.sh" -o "$TEMP_DIR/activate-window.sh" || {
            print_message "$RED" "✗ Failed to download activate-window.sh"
            rm -rf "$TEMP_DIR"
            exit 1
        }
    elif command_exists wget; then
        wget -q "https://raw.githubusercontent.com/$GITHUB_REPO/$GITHUB_BRANCH/activate-window.sh" -O "$TEMP_DIR/activate-window.sh" || {
            print_message "$RED" "✗ Failed to download activate-window.sh"
            rm -rf "$TEMP_DIR"
            exit 1
        }
    else
        print_message "$RED" "✗ curl or wget is required to download files"
        exit 1
    fi
    
    chmod +x "$TEMP_DIR/activate-window.sh"
    echo "$TEMP_DIR"
}

# Main installation
main() {
    print_message "$GREEN" "🚀 Installing Cursor Window Activator..."
    
    OS=$(detect_os)
    print_message "$GREEN" "✓ Detected OS: $OS"
    
    # Install Linux dependencies if needed
    if [ "$OS" = "linux" ]; then
        install_linux_dependencies
    fi
    
    # Determine script location
    SCRIPT_DIR=$(get_script_dir)
    HOOKS_DIR="$HOME/.cursor/hooks"
    SCRIPT_PATH="$HOOKS_DIR/activate-window.sh"
    
    # Create hooks directory
    print_message "$GREEN" "📁 Creating hooks directory..."
    mkdir -p "$HOOKS_DIR"
    mkdir -p "$HOOKS_DIR/activate-window-ids"
    
    # Copy activate-window.sh
    if [ -f "$SCRIPT_DIR/activate-window.sh" ]; then
        print_message "$GREEN" "📋 Copying activate-window.sh..."
        cp "$SCRIPT_DIR/activate-window.sh" "$SCRIPT_PATH"
        chmod +x "$SCRIPT_PATH"
        print_message "$GREEN" "✓ Script copied and made executable"
    else
        print_message "$RED" "✗ activate-window.sh not found in $SCRIPT_DIR"
        exit 1
    fi
    
    # Create or update hooks.json
    HOOKS_JSON="$HOME/.cursor/hooks.json"
    if [ -f "$HOOKS_JSON" ]; then
        print_message "$YELLOW" "⚠ hooks.json already exists"
        print_message "$GREEN" "📝 Updating hooks.json to add activate-window hooks..."
        
        if update_hooks_json "$HOOKS_JSON" "$SCRIPT_PATH"; then
            print_message "$GREEN" "✓ hooks.json updated successfully"
        else
            print_message "$YELLOW" "⚠ Could not automatically update hooks.json"
            print_message "$YELLOW" "  Please manually add the following hooks to your hooks.json:"
            print_message "$YELLOW" "  - beforeSubmitPrompt: $SCRIPT_PATH"
            print_message "$YELLOW" "  - afterAgentResponse: $SCRIPT_PATH"
            print_message "$YELLOW" "  See hooks.json.example for reference"
        fi
    else
        print_message "$GREEN" "📝 Creating hooks.json..."
        # Create minimal hooks.json
        cat > "$HOOKS_JSON" <<EOF
{
  "version": 1,
  "hooks": {
    "beforeSubmitPrompt": [
      {
        "command": "$SCRIPT_PATH"
      }
    ],
    "afterAgentResponse": [
      {
        "command": "$SCRIPT_PATH"
      }
    ]
  }
}
EOF
        print_message "$GREEN" "✓ hooks.json created"
    fi
    
    # Note: Temp directory cleanup is handled automatically by the system
    
    print_message "$GREEN" ""
    print_message "$GREEN" "✅ Installation complete!"
    print_message "$GREEN" ""
    print_message "$YELLOW" "📌 Important: Restart Cursor for hooks to take effect"
    print_message "$YELLOW" ""
    print_message "$GREEN" "Files installed at:"
    print_message "$GREEN" "  - $SCRIPT_PATH"
    print_message "$GREEN" "  - $HOOKS_JSON"
    print_message "$GREEN" ""
}

# Run installation
main "$@"
