#!/usr/bin/env node

/**
 * Unified hook script to handle window activation
 * Handles both beforeSubmitPrompt (save window ID) and afterAgentResponse (activate window)
 * Cross-platform support: macOS, Linux, Windows
 */

import { activeWindow } from 'get-windows';
import { windowManager } from 'node-window-manager';
import * as fs from 'fs';
import * as path from 'path';
import * as os from 'os';
import { fileURLToPath } from 'url';

/**
 * Get storage directory for window IDs
 */
function getStorageDir() {
  // Storage is in activate-window/ids directory (relative to script location)
  const __filename = fileURLToPath(import.meta.url);
  const scriptDir = path.dirname(__filename);
  const idsDir = path.join(scriptDir, 'ids');
  if (!fs.existsSync(idsDir)) {
    fs.mkdirSync(idsDir, { recursive: true });
  }
  return idsDir;
}

/**
 * Get the current active window
 * Returns the active window if it's a Cursor window, otherwise returns null
 */
async function getFrontWindow() {
  try {
    const window = await activeWindow();
    if (!window) {
      return null;
    }

    // Always return the active window (not just Cursor windows)
    // This allows the hook to work even if user switches to another app
    return {
      id: window.id,
      title: window.title || '',
      owner: window.owner?.name || '',
      platform: window.platform,
      processId: window.owner?.processId,
    };
  } catch (error) {
    console.error('Error getting front window:', error);
    return null;
  }
}

/**
 * Activate Cursor application (fallback)
 */
async function activateCursor() {
  try {
    const windows = windowManager.getWindows();
    const cursorWindows = windows.filter((w) => {
      try {
        const title = w.getTitle().toLowerCase();
        const processName = w.getProcessName()?.toLowerCase() || '';
        return title.includes('cursor') || processName.includes('cursor');
      } catch {
        return false;
      }
    });

    if (cursorWindows.length > 0) {
      cursorWindows[0].bringToTop();
      return true;
    }
    return false;
  } catch (error) {
    console.error('Error activating Cursor:', error);
    return false;
  }
}

/**
 * Activate specific window by ID
 */
async function activateWindowById(windowData) {
  if (!windowData) {
    return activateCursor();
  }

  try {
    const windows = windowManager.getWindows();
    
    // Try to find window by ID first
    let targetWindow = windows.find((w) => {
      try {
        return w.id === windowData.id;
      } catch {
        return false;
      }
    });

    // If not found by ID, try to find by process ID
    if (!targetWindow && windowData.processId) {
      targetWindow = windows.find((w) => {
        try {
          return w.getProcessId() === windowData.processId;
        } catch {
          return false;
        }
      });
    }

    // If still not found, try to find by title (for compatibility)
    if (!targetWindow && windowData.title) {
      targetWindow = windows.find((w) => {
        try {
          const title = w.getTitle();
          return title && title === windowData.title;
        } catch {
          return false;
        }
      });
    }

    if (targetWindow) {
      targetWindow.bringToTop();
      return true;
    }

    // Fallback to activating any Cursor window
    return activateCursor();
  } catch (error) {
    console.error('Error activating window by ID:', error);
    return activateCursor();
  }
}

/**
 * Main function
 */
async function main() {
  // Read JSON input from stdin
  let input = '';
  for await (const chunk of process.stdin) {
    input += chunk.toString();
  }

  if (!input.trim()) {
    // No input, just activate Cursor as fallback
    await activateCursor();
    process.exit(0);
  }

  // Parse JSON input
  let data;
  try {
    data = JSON.parse(input);
  } catch (error) {
    console.error('Error parsing JSON input:', error);
    await activateCursor();
    process.exit(0);
  }

  const hookEventName = data.hook_event_name;
  const conversationId = data.conversation_id;

  const storageDir = getStorageDir();

  // Handle different hook events
  switch (hookEventName) {
    case 'beforeSubmitPrompt': {
      // Save the current front window identifier before submitting prompt
      const window = await getFrontWindow();

      if (conversationId && window) {
        // Save window ID with conversation_id as key
        const filePath = path.join(storageDir, `${conversationId}.txt`);
        fs.writeFileSync(filePath, JSON.stringify(window), 'utf-8');
      }
      break;
    }

    case 'afterAgentResponse': {
      // Activate the saved window after agent response
      if (conversationId) {
        const filePath = path.join(storageDir, `${conversationId}.txt`);

        if (fs.existsSync(filePath)) {
          try {
            const windowData = JSON.parse(fs.readFileSync(filePath, 'utf-8'));

            if (windowData && (windowData.id || windowData.title || windowData.processId)) {
              // Activate the specific window
              await activateWindowById(windowData);

              // Clean up the saved window identifier file after use
              fs.unlinkSync(filePath);
            } else {
              await activateCursor();
            }
          } catch (error) {
            console.error('Error reading window data:', error);
            await activateCursor();
          }
        } else {
          // Fallback: just activate Cursor if no saved window identifier found
          await activateCursor();
        }
      } else {
        await activateCursor();
      }
      break;
    }

    default: {
      // Unknown event, just activate Cursor as fallback
      await activateCursor();
      break;
    }
  }

  process.exit(0);
}

// Run main function
main().catch((error) => {
  console.error('Unexpected error:', error);
  process.exit(1);
});
