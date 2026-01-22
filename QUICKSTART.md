# Quick Start

## One-command Installation

```bash
# Via curl
curl -fsSL https://raw.githubusercontent.com/beautyfree/cursor-window-activate-hook/main/install.sh | bash

# Or via wget
wget -qO- https://raw.githubusercontent.com/beautyfree/cursor-window-activate-hook/main/install.sh | bash
```

## Installation from Repository

```bash
# Clone and install
git clone https://github.com/beautyfree/cursor-window-activate-hook.git
cd cursor-window-activate-hook
./install.sh
```

## After Installation

1. **Restart Cursor** - This is required for hooks to activate
2. Done! The Cursor window will now automatically activate after each agent response

## Testing

After restarting Cursor, send any prompt to the agent. The Cursor window should automatically come to the foreground after receiving a response.

## Uninstallation

```bash
rm -rf ~/.cursor/hooks/activate-window.sh
rm -rf ~/.cursor/hooks/activate-window-ids
# Edit ~/.cursor/hooks.json and remove the corresponding entries
```
