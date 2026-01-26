# Cursor Window Activate Hook

Automatically activates the Cursor window and brings it to the foreground after each AI agent response. Saves the active window before submitting a prompt and restores it after receiving a response.

<p align="center">
  <img src=".github/demo.gif" alt="Demo" />
</p>

## 🎯 Features

- ✅ Automatic Cursor window activation after agent response
- ✅ Save active window before submitting prompt
- ✅ Restore the same window after response
- ✅ Cross-platform support: macOS, Linux, Windows
- ✅ Works with multiple Cursor windows simultaneously

## 🚀 Quick Installation

Install using the [cursor-hook](https://github.com/beautyfree/cursor-hook) CLI tool:

```bash
npx cursor-hook install beautyfree/cursor-window-activate-hook
```

### Dependencies

The hook requires Node.js dependencies which are automatically installed and compiled during setup:
- Hook dependencies (including TypeScript) are installed using `npm install`
- TypeScript code is automatically compiled to JavaScript using `npm run build`
- The compiled JavaScript runs via Node.js
- The CLI installs and compiles everything silently without verbose output

## 📋 Requirements

### macOS
- Cursor installed
- Node.js (>=18.0.0) and npm (for installing dependencies and compiling TypeScript)
- No additional dependencies (uses built-in AppleScript)

### Linux
- Cursor installed
- Node.js (>=18.0.0) and npm (for installing dependencies and compiling TypeScript)
- `xdotool` or `wmctrl` (for window management, install manually if needed)

### Windows
- Cursor installed
- Node.js (>=18.0.0) and npm (for installing dependencies and compiling TypeScript)
- PowerShell (built-in on Windows 10+)

## 🔧 How It Works

1. **Before submitting prompt** (`beforeSubmitPrompt`):
   - Script saves the identifier of the current active window
   - Saves it to `~/.cursor/hooks/activate-window/ids/`

2. **After agent response** (`afterAgentResponse`):
   - Script loads the saved window identifier
   - Activates that specific window and brings it to the foreground
   - Removes the temporary file after use

## 📁 File Structure

After installation, files will be located at:

**Global installation:**
```
~/.cursor/
├── hooks.json                    # Hooks configuration
└── hooks/
    └── activate-window/           # Hook directory
        ├── activate-window.ts     # Main TypeScript script
        ├── utils.ts               # Utility functions
        ├── types.ts               # TypeScript type definitions
        ├── dist/                  # Compiled JavaScript (created during installation)
        │   ├── activate-window.js  # Compiled main script
        │   ├── utils.js           # Compiled utilities
        │   └── types.js           # Compiled types
        ├── package.json           # Node.js dependencies and build scripts
        ├── tsconfig.json          # TypeScript configuration
        ├── node_modules/          # Installed dependencies (created automatically)
        └── ids/                  # Temporary files with window IDs (created automatically)
```

**Project installation:**
```
.cursor/
├── hooks.json                    # Hooks configuration
└── hooks/
    └── activate-window/           # Hook directory
        ├── activate-window.ts     # Main TypeScript script
        ├── utils.ts               # Utility functions
        ├── types.ts               # TypeScript type definitions
        ├── dist/                  # Compiled JavaScript (created during installation)
        │   ├── activate-window.js  # Compiled main script
        │   ├── utils.js           # Compiled utilities
        │   └── types.js           # Compiled types
        ├── package.json           # Node.js dependencies and build scripts
        ├── tsconfig.json          # TypeScript configuration
        ├── node_modules/          # Installed dependencies (created automatically)
        └── ids/                  # Temporary files with window IDs (created automatically)
```

## 🛠️ Manual Setup

If you prefer to set up manually:

1. Download the `activate-window` directory from the repository
2. Copy it to `~/.cursor/hooks/` (or `.cursor/hooks/` for project installation)
3. Install dependencies and compile: `cd ~/.cursor/hooks/activate-window && npm install && npm run build`
4. Create or update `~/.cursor/hooks.json` (or `.cursor/hooks.json` for project) with hooks configuration:
   ```json
   {
     "version": 1,
     "hooks": {
       "beforeSubmitPrompt": [
         {
           "command": "node $HOME/.cursor/hooks/activate-window/dist/activate-window.js"
         }
       ],
       "afterAgentResponse": [
         {
           "command": "node $HOME/.cursor/hooks/activate-window/dist/activate-window.js"
         }
       ]
     }
   }
   ```

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
}' | node ~/.cursor/hooks/activate-window/dist/activate-window.js

# Check saved ID
cat ~/.cursor/hooks/activate-window/ids/test-123.txt

# Test window activation
echo '{
  "conversation_id": "test-123",
  "hook_event_name": "afterAgentResponse",
  "cursor_version": "2.4.20",
  "workspace_roots": ["/path/to/workspace"],
  "user_email": "test@example.com"
}' | node ~/.cursor/hooks/activate-window/dist/activate-window.js
```

## 🔄 Updating

```bash
npx cursor-hook install beautyfree/cursor-window-activate-hook
```

## 🗑️ Uninstallation

**For global installation:**
```bash
# Remove hooks and scripts
rm -rf ~/.cursor/hooks/activate-window
# Edit ~/.cursor/hooks.json and remove the corresponding entries
```

**For project installation:**
```bash
# Remove hooks and scripts
rm -rf .cursor/hooks/activate-window
# Edit .cursor/hooks.json and remove the corresponding entries
```

## 📝 License

MIT

## 🤝 Contributing

Pull requests are welcome! For major changes, please open an issue first to discuss what you would like to change.

## 📚 Additional Information

- [Cursor Hooks Documentation](https://cursor.com/docs/agent/hooks)
- [cursor-hook](https://github.com/beautyfree/cursor-hook) - Develop and install hooks from Git repositories
- [Issues and Discussions](https://github.com/beautyfree/cursor-window-activate-hook/issues)
