#!/usr/bin/env node

/**
 * Unified hook script to handle window activation
 * Handles both beforeSubmitPrompt (save window ID) and afterAgentResponse (activate window)
 * Cross-platform support: macOS, Linux, Windows
 */

import { activeWindow } from 'get-windows'
import { windowManager } from 'node-window-manager'
import type {
  AfterAgentResponsePayload,
  BeforeSubmitPromptPayload,
  BeforeSubmitPromptResponse,
  HookPayload,
} from './types.js'
import {
  type WindowData,
  deleteWindowData,
  findWindowByData,
  getStorageDir,
  isCursorWindow,
  loadWindowData,
  saveWindowData,
} from './utils.js'

/**
 * Get the current active window
 */
async function getFrontWindow(): Promise<WindowData | null> {
  try {
    const window = await activeWindow()
    if (!window) return null

    return {
      id: window.id,
      title: window.title || '',
      owner: window.owner?.name || '',
      platform: window.platform,
      processId: window.owner?.processId,
    }
  } catch (error) {
    console.error('Error getting front window:', error)
    return null
  }
}

/**
 * Activate Cursor application (fallback)
 */
async function activateCursor(): Promise<boolean> {
  try {
    const windows = windowManager.getWindows()
    const cursorWindow = windows.find(isCursorWindow)

    if (cursorWindow) {
      cursorWindow.bringToTop()
      return true
    }

    return false
  } catch (error) {
    console.error('Error activating Cursor:', error)
    return false
  }
}

/**
 * Activate specific window by data
 */
async function activateWindowByData(
  windowData: WindowData | null
): Promise<boolean> {
  if (!windowData) {
    return activateCursor()
  }

  try {
    const windows = windowManager.getWindows()
    const targetWindow = findWindowByData(windows, windowData)

    if (targetWindow) {
      targetWindow.bringToTop()
      return true
    }

    return activateCursor()
  } catch (error) {
    console.error('Error activating window:', error)
    return activateCursor()
  }
}

/**
 * Handle beforeSubmitPrompt event
 */
async function handleBeforeSubmitPrompt(
  input: BeforeSubmitPromptPayload,
  storageDir: string
): Promise<void> {
  const window = await getFrontWindow()

  if (input.conversation_id && window) {
    saveWindowData(storageDir, input.conversation_id, window)
  }

  const output: BeforeSubmitPromptResponse = { continue: true }
  console.log(JSON.stringify(output, null, 2))
}

/**
 * Handle afterAgentResponse event
 */
async function handleAfterAgentResponse(
  input: AfterAgentResponsePayload,
  storageDir: string
): Promise<void> {
  const windowData = loadWindowData(storageDir, input.conversation_id)

  if (
    !windowData ||
    (!windowData.id && !windowData.title && !windowData.processId)
  ) {
    await activateCursor()
    return
  }

  await activateWindowByData(windowData)
  deleteWindowData(storageDir, input.conversation_id)
}

/**
 * Main function
 */
async function main(): Promise<void> {
  const storageDir = getStorageDir()

  try {
    // Read JSON from stdin
    let input = ''
    for await (const chunk of process.stdin) {
      input += chunk.toString()
    }
    const data: HookPayload = JSON.parse(input)

    if (data.hook_event_name === 'beforeSubmitPrompt') {
      await handleBeforeSubmitPrompt(data, storageDir)
    } else if (data.hook_event_name === 'afterAgentResponse') {
      await handleAfterAgentResponse(data, storageDir)
    } else {
      await activateCursor()
    }
  } catch (error) {
    console.error('Error reading/parsing JSON input:', error)
    await activateCursor()
  }

  process.exit(0)
}

// Run main function
main().catch((error) => {
  console.error('Unexpected error:', error)
  process.exit(1)
})
