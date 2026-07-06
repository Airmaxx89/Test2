const { app, BrowserWindow, ipcMain, dialog, shell } = require('electron');
const path = require('path');
const fs = require('fs');
const cron = require('node-cron');
const crypto = require('crypto');

const STORE_PATH = path.join(app.getPath('userData'), 'schedules.json');

let mainWindow = null;
let entries = [];
const cronJobs = new Map(); // entryId -> cron task
let onceCheckerInterval = null;

function loadEntries() {
  try {
    const raw = fs.readFileSync(STORE_PATH, 'utf-8');
    entries = JSON.parse(raw);
  } catch {
    entries = [];
  }
}

function saveEntries() {
  fs.writeFileSync(STORE_PATH, JSON.stringify(entries, null, 2), 'utf-8');
}

function notifyRenderer(message) {
  if (mainWindow) {
    mainWindow.webContents.send('schedule:notify', {
      message,
      time: new Date().toISOString(),
    });
  }
}

function sendEntries() {
  if (mainWindow) {
    mainWindow.webContents.send('schedule:updated', entries);
  }
}

async function openEntryFile(entry) {
  const result = await shell.openPath(entry.filePath);
  if (result) {
    notifyRenderer(`Fehler beim Öffnen von "${entry.filePath}": ${result}`);
  } else {
    notifyRenderer(`Datei geöffnet: ${entry.filePath}`);
    entry.lastOpened = new Date().toISOString();
    if (entry.type === 'once') {
      entry.doneOnce = true;
    }
    saveEntries();
    sendEntries();
  }
}

function cronExpression(entry) {
  const [hh, mm] = entry.time.split(':').map(Number);
  if (entry.type === 'daily') {
    return `${mm} ${hh} * * *`;
  }
  if (entry.type === 'weekly') {
    return `${mm} ${hh} * * ${entry.weekday}`;
  }
  return null;
}

function rebuildCronJobs() {
  for (const task of cronJobs.values()) {
    task.stop();
  }
  cronJobs.clear();

  for (const entry of entries) {
    if (!entry.enabled) continue;
    if (entry.type !== 'daily' && entry.type !== 'weekly') continue;
    const expr = cronExpression(entry);
    if (!expr || !cron.validate(expr)) continue;
    const task = cron.schedule(expr, () => openEntryFile(entry));
    cronJobs.set(entry.id, task);
  }
}

function checkOnceEntries() {
  const now = new Date();
  for (const entry of entries) {
    if (entry.type !== 'once' || !entry.enabled || entry.doneOnce) continue;
    const scheduled = new Date(`${entry.date}T${entry.time}:00`);
    if (now >= scheduled) {
      openEntryFile(entry);
    }
  }
}

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 900,
    height: 700,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
    },
  });

  mainWindow.loadFile(path.join(__dirname, 'renderer', 'index.html'));
}

app.whenReady().then(() => {
  loadEntries();
  rebuildCronJobs();
  onceCheckerInterval = setInterval(checkOnceEntries, 15000);
  createWindow();

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

app.on('window-all-closed', () => {
  if (onceCheckerInterval) clearInterval(onceCheckerInterval);
  for (const task of cronJobs.values()) task.stop();
  if (process.platform !== 'darwin') app.quit();
});

ipcMain.handle('dialog:chooseFile', async () => {
  const result = await dialog.showOpenDialog(mainWindow, {
    properties: ['openFile'],
  });
  if (result.canceled || result.filePaths.length === 0) return null;
  return result.filePaths[0];
});

ipcMain.handle('schedule:getAll', () => entries);

ipcMain.handle('schedule:add', (_event, data) => {
  const entry = {
    id: crypto.randomUUID(),
    filePath: data.filePath,
    type: data.type, // 'once' | 'daily' | 'weekly'
    date: data.date || null, // for 'once'
    time: data.time,
    weekday: data.weekday ?? null, // for 'weekly', 0-6
    enabled: true,
    doneOnce: false,
    lastOpened: null,
    createdAt: new Date().toISOString(),
  };
  entries.push(entry);
  saveEntries();
  rebuildCronJobs();
  return entries;
});

ipcMain.handle('schedule:delete', (_event, id) => {
  entries = entries.filter((e) => e.id !== id);
  saveEntries();
  rebuildCronJobs();
  return entries;
});

ipcMain.handle('schedule:toggle', (_event, id) => {
  const entry = entries.find((e) => e.id === id);
  if (entry) {
    entry.enabled = !entry.enabled;
    if (entry.type === 'once' && entry.enabled) entry.doneOnce = false;
    saveEntries();
    rebuildCronJobs();
  }
  return entries;
});

ipcMain.handle('schedule:openNow', async (_event, id) => {
  const entry = entries.find((e) => e.id === id);
  if (entry) await openEntryFile(entry);
  return entries;
});
