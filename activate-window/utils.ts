import * as fs from 'fs'
import * as path from 'path'
import { fileURLToPath } from 'url'
import { Window } from 'node-window-manager'

export interface WindowData {
  id?: number | string
  title?: string
  owner?: string
  platform?: string
  processId?: number
}

// Constants
const CURSOR_KEYWORD = 'cursor'

/**
 * Get storage directory for window IDs
 */
export function getStorageDir(): string {
  const __filename = fileURLToPath(import.meta.url)
  const scriptDir = path.dirname(__filename)
  const idsDir = path.join(scriptDir, 'ids')

  if (!fs.existsSync(idsDir)) {
    fs.mkdirSync(idsDir, { recursive: true })
  }

  return idsDir
}

/**
 * Get file path for storing window data by conversation ID
 */
export function getWindowDataPath(
  storageDir: string,
  conversationId: string
): string {
  return path.join(storageDir, `${conversationId}.txt`)
}

/**
 * Save window data to file
 */
export function saveWindowData(
  storageDir: string,
  conversationId: string,
  window: WindowData
): void {
  const filePath = getWindowDataPath(storageDir, conversationId)
  fs.writeFileSync(filePath, JSON.stringify(window), 'utf-8')
}

/**
 * Load window data from file
 */
export function loadWindowData(
  storageDir: string,
  conversationId: string
): WindowData | null {
  const filePath = getWindowDataPath(storageDir, conversationId)

  if (!fs.existsSync(filePath)) {
    return null
  }

  try {
    const content = fs.readFileSync(filePath, 'utf-8')
    return JSON.parse(content) as WindowData
  } catch {
    return null
  }
}

/**
 * Delete window data file
 */
export function deleteWindowData(
  storageDir: string,
  conversationId: string
): void {
  const filePath = getWindowDataPath(storageDir, conversationId)
  if (fs.existsSync(filePath)) {
    fs.unlinkSync(filePath)
  }
}

/**
 * Check if window is a Cursor window
 */
export function isCursorWindow(window: Window): boolean {
  try {
    const title = window.getTitle().toLowerCase()
    const windowPath = window.path?.toLowerCase() || ''
    return title.includes(CURSOR_KEYWORD) || windowPath.includes(CURSOR_KEYWORD)
  } catch {
    return false
  }
}

/**
 * Find window by data (tries multiple strategies)
 */
export function findWindowByData(
  windows: Window[],
  data: WindowData
): Window | null {
  // Try by ID
  const byId = windows.find((w) => w.id === data.id)
  if (byId) return byId

  // Try by process ID
  if (data.processId) {
    const byProcessId = windows.find((w) => w.processId === data.processId)
    if (byProcessId) return byProcessId
  }

  // Try by title
  if (data.title) {
    const byTitle = windows.find((w) => {
      try {
        return w.getTitle() === data.title
      } catch {
        return false
      }
    })
    if (byTitle) return byTitle
  }

  return null
}
