# Cursor Window Activator

Automatically activates the Cursor window and brings it to the foreground after each AI agent response. Saves the active window before submitting a prompt and restores it after receiving a response.


## 🎯 Features

- ✅ Automatic Cursor window activation after agent response
- ✅ Save active window before submitting prompt
- ✅ Restore the same window after response
- ✅ Cross-platform support: macOS, Linux, Windows
- ✅ Works with multiple Cursor windows simultaneously

## 🚀 Quick Installation

### One-command installation (recommended)

**Via curl:**
```bash
curl -fsSL https://raw.githubusercontent.com/beautyfree/cursor-window-activate-hook/main/install.sh | bash
```

**Via wget:**
```bash
wget -qO- https://raw.githubusercontent.com/beautyfree/cursor-window-activate-hook/main/install.sh | bash
```

The script automatically:
- Detects your OS
- Installs required dependencies (for Linux)
- Downloads and installs all necessary files
- Configures hooks.json (merges with existing hooks if present)

### Installation from cloned repository

```bash
# 1. Clone the repository
git clone https://github.com/beautyfree/cursor-window-activate-hook.git
cd cursor-window-activate-hook

# 2. Run the installation script
./install.sh
```

### Linux dependencies installation (automatic)

The installation script automatically detects and installs required dependencies:

- **Debian/Ubuntu**: `sudo apt-get install xdotool`
- **CentOS/RHEL**: `sudo yum install xdotool`
- **Fedora**: `sudo dnf install xdotool`
- **Arch Linux**: `sudo pacman -S xdotool`

If automatic installation fails, install manually using one of the commands above.

## 📋 Requirements

### macOS
- Cursor installed
- No additional dependencies (uses built-in AppleScript)

### Linux
- Cursor installed
- One of the following tools (installed automatically if needed):
  - `xdotool` (recommended)
  - `wmctrl`

### Windows
- Cursor installed
- PowerShell (built-in on Windows 10+)
- Works in WSL or Git Bash

## 🔧 How It Works

1. **Before submitting prompt** (`beforeSubmitPrompt`):
   - Script saves the identifier of the current active Cursor window
   - Saves it to `~/.cursor/hooks/activate-window-ids/`

2. **After agent response** (`afterAgentResponse`):
   - Script loads the saved window identifier
   - Activates that specific window and brings it to the foreground
   - Removes the temporary file after use

## 📁 File Structure

After installation, files will be located at:

```
~/.cursor/
├── hooks.json                    # Hooks configuration
└── hooks/
    ├── activate-window.sh         # Main script
    └── activate-window-ids/       # Temporary files with window IDs
```

## 🛠️ Manual Setup

If you want to set up manually:

1. Copy `activate-window.sh` to `~/.cursor/hooks/`
2. Make it executable: `chmod +x ~/.cursor/hooks/activate-window.sh`
3. Create or update `~/.cursor/hooks.json` (see `hooks.json.example`)

## 🧪 Testing

Test the script:

```bash
# Test window saving
echo '{
  "conversation_id": "test-123",
  "hook_event_name": "beforeSubmitPrompt",
  "cursor_version": "2.4.20",
  "workspace_roots": ["/path/to/workspace"],
  "user_email": "test@example.com"
}' | ~/.cursor/hooks/activate-window.sh

# Check saved ID
cat ~/.cursor/hooks/activate-window-ids/test-123.txt

# Test window activation
echo '{
  "conversation_id": "test-123",
  "hook_event_name": "afterAgentResponse",
  "cursor_version": "2.4.20",
  "workspace_roots": ["/path/to/workspace"],
  "user_email": "test@example.com"
}' | ~/.cursor/hooks/activate-window.sh
```

## 🔄 Updating

```bash
# Update to the latest version
curl -fsSL https://raw.githubusercontent.com/beautyfree/cursor-window-activate-hook/main/install.sh | bash
```

## 🗑️ Uninstallation

```bash
# Remove hooks and scripts
rm -rf ~/.cursor/hooks/activate-window.sh
rm -rf ~/.cursor/hooks/activate-window-ids
# Edit ~/.cursor/hooks.json and remove the corresponding entries
```

## 📝 License

MIT

## 🤝 Contributing

Pull requests are welcome! For major changes, please open an issue first to discuss what you would like to change.

## 📚 Additional Information

- [Cursor Hooks Documentation](https://cursor.com/docs/agent/hooks)
- [Issues and Discussions](https://github.com/beautyfree/cursor-window-activate-hook/issues)
