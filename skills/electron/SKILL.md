---
name: electron
description: >
  Electron patterns for cross-platform desktop apps: IPC, security, auto-updater, native menus.
  Trigger: When building Electron apps, working with main/renderer processes, IPC communication, or native OS integrations.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
format: reference
---

## When to Use

**Triggers**: When building Electron apps, working with main/renderer processes, IPC communication, or native OS integrations.

Load when: building Electron desktop apps, implementing IPC between main and renderer, handling native OS features, or setting up auto-updates.

## Critical Patterns — SECURITY

```typescript
// ✅ ALWAYS: contextIsolation + NO nodeIntegration
new BrowserWindow({
  webPreferences: {
    contextIsolation: true,      // MANDATORY
    nodeIntegration: false,      // NEVER enable
    preload: path.join(__dirname, 'preload.js'),
    sandbox: true,               // Recommended
  }
});

// ❌ NEVER: nodeIntegration enabled
new BrowserWindow({
  webPreferences: {
    nodeIntegration: true,  // Security VULNERABILITY
  }
});

// ❌ NEVER: use remote module (deprecated)
const { remote } = require('electron');

// ❌ NEVER: expose full ipcRenderer
contextBridge.exposeInMainWorld('api', { ipcRenderer }); // DANGEROUS
```

## Code Examples

### Main Process — Secure initialization

```typescript
// main/index.ts
import { app, BrowserWindow } from 'electron';
import path from 'path';

function createWindow() {
  const win = new BrowserWindow({
    width: 1200,
    height: 800,
    webPreferences: {
      contextIsolation: true,
      nodeIntegration: false,
      preload: path.join(__dirname, 'preload.js'),
    },
  });

  if (process.env.NODE_ENV === 'development') {
    win.loadURL('http://localhost:5173');
  } else {
    win.loadFile(path.join(__dirname, '../renderer/index.html'));
  }
}

app.whenReady().then(createWindow);
app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});
```

### Preload — Secure Context Bridge

```typescript
// preload.ts
import { contextBridge, ipcRenderer } from 'electron';

// Define typed channels
type Channels = 'read-file' | 'write-file' | 'open-dialog';

contextBridge.exposeInMainWorld('api', {
  // Only expose specific functions, not the full ipcRenderer
  readFile: (filePath: string) =>
    ipcRenderer.invoke('read-file', filePath),

  writeFile: (filePath: string, content: string) =>
    ipcRenderer.invoke('write-file', filePath, content),

  openDialog: (options: Electron.OpenDialogOptions) =>
    ipcRenderer.invoke('open-dialog', options),

  onProgress: (callback: (progress: number) => void) => {
    ipcRenderer.on('progress', (_, value) => callback(value));
    return () => ipcRenderer.removeAllListeners('progress');
  },
});
```

### IPC Handlers in Main

```typescript
// main/handlers.ts
import { ipcMain, dialog, app } from 'electron';
import fs from 'fs/promises';

ipcMain.handle('read-file', async (_, filePath: string) => {
  try {
    const content = await fs.readFile(filePath, 'utf-8');
    return { success: true, content };
  } catch (error) {
    return { success: false, error: String(error) };
  }
});

ipcMain.handle('write-file', async (_, filePath: string, content: string) => {
  await fs.writeFile(filePath, content, 'utf-8');
  return { success: true };
});

ipcMain.handle('open-dialog', async (_, options) => {
  const result = await dialog.showOpenDialog(options);
  return result;
});
```

### React Hook for IPC

```typescript
// hooks/useFileSystem.ts
import { useState } from 'react';

declare global {
  interface Window {
    api: {
      readFile: (path: string) => Promise<{ success: boolean; content?: string }>;
      writeFile: (path: string, content: string) => Promise<{ success: boolean }>;
      openDialog: (options: any) => Promise<Electron.OpenDialogReturnValue>;
    };
  }
}

export function useFileSystem() {
  const [isLoading, setIsLoading] = useState(false);

  const openAndReadFile = async () => {
    setIsLoading(true);
    try {
      const { canceled, filePaths } = await window.api.openDialog({
        properties: ['openFile'],
        filters: [{ name: 'Text', extensions: ['txt', 'md'] }],
      });
      if (canceled || !filePaths[0]) return null;

      const result = await window.api.readFile(filePaths[0]);
      return result.success ? result.content : null;
    } finally {
      setIsLoading(false);
    }
  };

  return { openAndReadFile, isLoading };
}
```

### Auto-Updater

```typescript
// main/updater.ts
import { autoUpdater } from 'electron-updater';
import { BrowserWindow } from 'electron';

export function setupAutoUpdater(win: BrowserWindow) {
  autoUpdater.autoDownload = false;

  autoUpdater.on('update-available', (info) => {
    win.webContents.send('update-available', info);
  });

  autoUpdater.on('download-progress', (progress) => {
    win.webContents.send('progress', progress.percent);
  });

  autoUpdater.on('update-downloaded', () => {
    win.webContents.send('update-ready');
  });

  autoUpdater.checkForUpdates();
}
```

## Anti-Patterns

### ❌ nodeIntegration: true

```typescript
// ❌ Allows the renderer to access Node.js — VULNERABILITY
webPreferences: { nodeIntegration: true }

// ✅ Use contextBridge + preload
webPreferences: { contextIsolation: true, preload: '...' }
```

### ❌ Expose full ipcRenderer

```typescript
// ❌ The renderer can listen/send on any channel
contextBridge.exposeInMainWorld('electron', { ipcRenderer });

// ✅ Only expose specific, typed functions
contextBridge.exposeInMainWorld('api', {
  readFile: (path: string) => ipcRenderer.invoke('read-file', path),
});
```

## Quick Reference

| Task | Pattern |
|------|---------|
| Secure window | `contextIsolation: true, nodeIntegration: false` |
| Expose API | `contextBridge.exposeInMainWorld('api', {...})` |
| Bidirectional IPC | `ipcMain.handle()` + `ipcRenderer.invoke()` |
| Unidirectional IPC | `ipcRenderer.send()` + `ipcMain.on()` |
| Main→renderer events | `win.webContents.send()` + `ipcRenderer.on()` |
| Native dialogs | `dialog.showOpenDialog()` in main |
| Auto-update | `electron-updater` |
| Native menu | `Menu.buildFromTemplate()` |

## Rules

- All IPC communication must go through named channels defined in `preload.js` — never expose the full `ipcRenderer` object to the renderer process
- `contextIsolation: true` and `nodeIntegration: false` are required security settings; do not relax them without explicit justification
- Long-running or blocking operations (file I/O, network) belong in the main process, not the renderer
- Auto-updater events must be handled explicitly; silent failures leave users on outdated versions
- Native OS integrations (menus, trays, notifications) must be set up in the main process lifecycle, not in renderer components
