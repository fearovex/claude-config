---
name: electron
description: >
  Electron patterns for cross-platform desktop apps: IPC, security, auto-updater, native menus.
  Trigger: When building Electron apps, working with main/renderer processes, IPC communication, or native OS integrations.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When to Use

Load when: building Electron desktop apps, implementing IPC between main and renderer, handling native OS features, or setting up auto-updates.

## Critical Patterns — SEGURIDAD

```typescript
// ✅ SIEMPRE: contextIsolation + NO nodeIntegration
new BrowserWindow({
  webPreferences: {
    contextIsolation: true,      // OBLIGATORIO
    nodeIntegration: false,      // NUNCA habilitar
    preload: path.join(__dirname, 'preload.js'),
    sandbox: true,               // Recomendado
  }
});

// ❌ NUNCA: nodeIntegration habilitado
new BrowserWindow({
  webPreferences: {
    nodeIntegration: true,  // VULNERABILIDAD de seguridad
  }
});

// ❌ NUNCA: usar remote module (deprecado)
const { remote } = require('electron');

// ❌ NUNCA: exponer ipcRenderer completo
contextBridge.exposeInMainWorld('api', { ipcRenderer }); // PELIGROSO
```

## Code Examples

### Main Process — Inicialización segura

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

### Preload — Context Bridge seguro

```typescript
// preload.ts
import { contextBridge, ipcRenderer } from 'electron';

// Define channels tipados
type Channels = 'read-file' | 'write-file' | 'open-dialog';

contextBridge.exposeInMainWorld('api', {
  // Solo expone funciones específicas, no ipcRenderer completo
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

### IPC Handlers en Main

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

### React Hook para IPC

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
// ❌ Permite al renderer acceder a Node.js — VULNERABILIDAD
webPreferences: { nodeIntegration: true }

// ✅ Usa contextBridge + preload
webPreferences: { contextIsolation: true, preload: '...' }
```

### ❌ Exponer ipcRenderer completo

```typescript
// ❌ El renderer puede escuchar/enviar cualquier canal
contextBridge.exposeInMainWorld('electron', { ipcRenderer });

// ✅ Solo exponer funciones específicas y tipadas
contextBridge.exposeInMainWorld('api', {
  readFile: (path: string) => ipcRenderer.invoke('read-file', path),
});
```

## Quick Reference

| Task | Patrón |
|------|--------|
| Window segura | `contextIsolation: true, nodeIntegration: false` |
| Exponer API | `contextBridge.exposeInMainWorld('api', {...})` |
| IPC bidireccional | `ipcMain.handle()` + `ipcRenderer.invoke()` |
| IPC unidireccional | `ipcRenderer.send()` + `ipcMain.on()` |
| Eventos main→renderer | `win.webContents.send()` + `ipcRenderer.on()` |
| Diálogos nativos | `dialog.showOpenDialog()` en main |
| Auto-update | `electron-updater` |
| Menú nativo | `Menu.buildFromTemplate()` |
