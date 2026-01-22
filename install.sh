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

# Print colored message (to stderr to avoid interfering with function return values)
print_message() {
    local color=$1
    shift
    echo -e "${color}$@${NC}" >&2
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Convert path to Windows format if on Windows
convert_to_windows_path() {
    local path="$1"
    local os=$(detect_os)

    if [ "$os" = "windows" ]; then
        # Simple conversion: /c/Users/... -> C:\Users\...
        if echo "$path" | grep -q "^/[a-zA-Z]/"; then
            # Extract drive letter and convert to uppercase
            local drive=$(echo "$path" | sed 's|^/\([a-zA-Z]\)/.*|\1|' | tr 'a-z' 'A-Z')
            # Remove leading /drive/ and convert slashes to backslashes
            local rest=$(echo "$path" | sed "s|^/[a-zA-Z]/||" | tr '/' '\\')
            echo "${drive}:\\${rest}"
        else
            # For other paths, just convert slashes to backslashes
            echo "$path" | tr '/' '\\'
        fi
    else
        echo "$path"
    fi
}

# Escape backslashes for JSON (Windows paths need \\ instead of \)
escape_path_for_json() {
    local path="$1"
    # Simple and reliable: use sed to replace \ with \\
    local result=$(echo "$path" | sed 's|\\|\\\\|g')
    # Debug: ensure result is not empty
    if [ -z "$result" ]; then
        echo "$path"
    else
        echo "$result"
    fi
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
    # Don't print here - let main() handle the output to avoid duplication
    if [ -f "$hooks_json" ] && [ -s "$hooks_json" ]; then
        return 1
    fi
    
    return 1
}

# Get script directory or download from GitHub
get_script_dir() {
    local script_dir=""
    GITHUB_REPO="beautyfree/cursor-window-activate-hook"
    GITHUB_BRANCH="main"
    
    # Check if we're running from a file (not via pipe)
    if [ -f "$0" ] && [ "$0" != "/dev/stdin" ] && [ "$0" != "-" ]; then
        # Try to get the directory where the script is located
        if [ -L "$0" ]; then
            # If script is a symlink, resolve it
            script_dir=$(dirname "$(readlink -f "$0" 2>/dev/null || readlink "$0")")
        else
            script_dir=$(cd "$(dirname "$0")" 2>/dev/null && pwd)
        fi
        
        # Check if we're running from a cloned repo (activate-window.sh exists)
        if [ -n "$script_dir" ] && [ -f "$script_dir/activate-window.sh" ]; then
            printf "%s\n" "$script_dir"
            return 0
        fi
    fi
    
    # If not found locally, we're running via curl - download files to temp directory
    local temp_dir
    if command_exists mktemp; then
        temp_dir=$(mktemp -d 2>/dev/null)
    else
        # Fallback for systems without mktemp
        temp_dir="/tmp/cursor-hook-install-$$"
        mkdir -p "$temp_dir" 2>/dev/null || {
            print_message "$RED" "✗ Failed to create temporary directory"
            exit 1
        }
    fi
    
    if [ -z "$temp_dir" ] || [ ! -d "$temp_dir" ]; then
        print_message "$RED" "✗ Failed to create temporary directory"
        exit 1
    fi
    
    print_message "$YELLOW" "📥 Downloading files from GitHub..."
    
    # Download activate-window.sh
    if command_exists curl; then
        if ! curl -fsSL "https://raw.githubusercontent.com/$GITHUB_REPO/$GITHUB_BRANCH/activate-window.sh" -o "$temp_dir/activate-window.sh"; then
            print_message "$RED" "✗ Failed to download activate-window.sh"
            rm -rf "$temp_dir"
            exit 1
        fi
    elif command_exists wget; then
        if ! wget -q "https://raw.githubusercontent.com/$GITHUB_REPO/$GITHUB_BRANCH/activate-window.sh" -O "$temp_dir/activate-window.sh"; then
            print_message "$RED" "✗ Failed to download activate-window.sh"
            rm -rf "$temp_dir"
            exit 1
        fi
    else
        print_message "$RED" "✗ curl or wget is required to download files"
        rm -rf "$temp_dir"
        exit 1
    fi
    
    # Verify file was downloaded and is not empty
    if [ ! -f "$temp_dir/activate-window.sh" ]; then
        print_message "$RED" "✗ Downloaded file not found"
        rm -rf "$temp_dir"
        exit 1
    fi
    
    if [ ! -s "$temp_dir/activate-window.sh" ]; then
        print_message "$RED" "✗ Downloaded file is empty"
        rm -rf "$temp_dir"
        exit 1
    fi
    
    chmod +x "$temp_dir/activate-window.sh" 2>/dev/null || true
    # Output only the directory path to stdout (for variable assignment)
    # All print_message calls above go to stderr, so they won't interfere
    printf "%s\n" "$temp_dir"
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
    # Note: print_message outputs to stderr (>&2), so only printf goes to stdout
    SCRIPT_DIR=$(get_script_dir)
    
    # Clean up any potential newlines, carriage returns, or extra whitespace
    SCRIPT_DIR=$(printf "%s" "$SCRIPT_DIR" | tr -d '\n\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    if [ -z "$SCRIPT_DIR" ]; then
        print_message "$RED" "✗ Failed to determine script directory"
        exit 1
    fi
    
    # Verify the directory exists and contains the file
    if [ ! -d "$SCRIPT_DIR" ] || [ ! -f "$SCRIPT_DIR/activate-window.sh" ]; then
        print_message "$RED" "✗ Invalid script directory or file not found"
        print_message "$RED" "  Directory: $SCRIPT_DIR"
        print_message "$RED" "  Expected file: $SCRIPT_DIR/activate-window.sh"
        exit 1
    fi
    
    HOOKS_DIR="$HOME/.cursor/hooks"
    SCRIPT_PATH="$HOOKS_DIR/activate-window.sh"
    
    # Create hooks directory
    print_message "$GREEN" "📁 Creating hooks directory..."
    mkdir -p "$HOOKS_DIR" || {
        print_message "$RED" "✗ Failed to create hooks directory: $HOOKS_DIR"
        exit 1
    }
    mkdir -p "$HOOKS_DIR/activate-window-ids" || {
        print_message "$RED" "✗ Failed to create activate-window-ids directory"
        exit 1
    }
    
    # Copy activate-window.sh
    if [ -f "$SCRIPT_DIR/activate-window.sh" ]; then
        print_message "$GREEN" "📋 Copying activate-window.sh..."
        if cp "$SCRIPT_DIR/activate-window.sh" "$SCRIPT_PATH"; then
            chmod +x "$SCRIPT_PATH"
            print_message "$GREEN" "✓ Script copied and made executable"
        else
            print_message "$RED" "✗ Failed to copy activate-window.sh"
            exit 1
        fi
    else
        print_message "$RED" "✗ activate-window.sh not found"
        print_message "$RED" "  Expected location: $SCRIPT_DIR/activate-window.sh"
        exit 1
    fi
    
    # Convert path to Windows format for hooks.json if on Windows
    SCRIPT_PATH_WIN=$(convert_to_windows_path "$SCRIPT_PATH")
    # For JSON, paths need to have backslashes escaped (\\ instead of \)
    # jq with --arg handles this automatically, but for manual JSON we need to escape
    # Store Windows format path - it will be properly escaped by jq or escape_path_for_json
    SCRIPT_PATH_FOR_JSON="$SCRIPT_PATH_WIN"
    
    
    # Create or update hooks.json
    HOOKS_JSON="$HOME/.cursor/hooks.json"
    hooks_updated=false
    if [ -f "$HOOKS_JSON" ]; then
        print_message "$YELLOW" "⚠ hooks.json already exists"
        print_message "$GREEN" "📝 Updating hooks.json to add activate-window hooks..."
        
        if update_hooks_json "$HOOKS_JSON" "$SCRIPT_PATH_FOR_JSON"; then
            print_message "$GREEN" "✓ hooks.json updated successfully"
            hooks_updated=true
        else
            hooks_updated=false
        fi
    else
        print_message "$GREEN" "📝 Creating hooks.json..."
        # Create minimal hooks.json
        # Use jq if available for proper JSON escaping, otherwise use printf
        hooks_updated=true  # New file created successfully
        if command_exists jq; then
            jq -n \
                --arg script "$SCRIPT_PATH_FOR_JSON" \
                '{
                  version: 1,
                  hooks: {
                    beforeSubmitPrompt: [{command: $script}],
                    afterAgentResponse: [{command: $script}]
                  }
                }' > "$HOOKS_JSON"
        else
            # Manual JSON creation with proper escaping
            # Escape backslashes for JSON (each \ becomes \\)
            # Use escape_path_for_json function for consistent escaping
            local escaped_path=$(escape_path_for_json "$SCRIPT_PATH_FOR_JSON")
            # Also escape quotes if any (though paths shouldn't have quotes)
            escaped_path=$(echo "$escaped_path" | sed 's/"/\\"/g')
            cat > "$HOOKS_JSON" <<EOF
{
  "version": 1,
  "hooks": {
    "beforeSubmitPrompt": [
      {
        "command": "$escaped_path"
      }
    ],
    "afterAgentResponse": [
      {
        "command": "$escaped_path"
      }
    ]
  }
}
EOF
        fi
        print_message "$GREEN" "✓ hooks.json created"
    fi

    # Note: Temp directory cleanup is handled automatically by the system

    print_message "$GREEN" ""
    print_message "$GREEN" "✅ Installation complete!"
    print_message "$GREEN" ""
    print_message "$YELLOW" "📌 Important: Restart Cursor for hooks to take effect"
    print_message "$YELLOW" ""
    print_message "$GREEN" "Files installed at:"
    # Show Windows path (for file system) - SCRIPT_PATH_FOR_JSON is already converted
    printf "$GREEN  - %s$NC\n" "$SCRIPT_PATH_FOR_JSON"
    # Convert hooks.json path for display on Windows
    HOOKS_JSON_DISPLAY=$(convert_to_windows_path "$HOOKS_JSON")
    print_message "$GREEN" "  - $HOOKS_JSON_DISPLAY"
    print_message "$GREEN" ""
    
    # Show JSON-escaped path for manual copy-paste (only if update failed)
    if [ "$hooks_updated" = false ]; then
        print_message "$YELLOW" "⚠ Could not automatically update hooks.json (jq not found)"
        print_message "$YELLOW" "  Please manually add the following to your hooks.json:"
        # Show escaped path for JSON (with double backslashes for easy copy-paste)
        local json_path=$(escape_path_for_json "$SCRIPT_PATH_FOR_JSON")
        if [ -n "$json_path" ]; then
            printf "$YELLOW$NC\n" >&2
            printf "$YELLOW  Copy these lines (paths have DOUBLE backslashes for JSON):$NC\n" >&2
            printf "$YELLOW  \"beforeSubmitPrompt\": [{\"command\": \"%s\"}],$NC\n" "$json_path" >&2
            printf "$YELLOW  \"afterAgentResponse\": [{\"command\": \"%s\"}],$NC\n" "$json_path" >&2
            printf "$YELLOW$NC\n" >&2
            printf "$YELLOW  Or just the path: \"%s\"$NC\n" "$json_path" >&2
        else
            printf "$YELLOW  Path: %s$NC\n" "$SCRIPT_PATH_FOR_JSON" >&2
            print_message "$YELLOW" "  (Manually escape backslashes: replace \\ with \\\\)"
        fi
        print_message "$YELLOW" "  See hooks.json.example for reference"
        print_message "$GREEN" ""
    fi
}

# Run installation
main "$@"
