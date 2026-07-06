const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('api', {
  chooseFile: () => ipcRenderer.invoke('dialog:chooseFile'),
  getAll: () => ipcRenderer.invoke('schedule:getAll'),
  add: (data) => ipcRenderer.invoke('schedule:add', data),
  remove: (id) => ipcRenderer.invoke('schedule:delete', id),
  toggle: (id) => ipcRenderer.invoke('schedule:toggle', id),
  openNow: (id) => ipcRenderer.invoke('schedule:openNow', id),
  onUpdated: (callback) => {
    ipcRenderer.on('schedule:updated', (_event, entries) => callback(entries));
  },
  onNotify: (callback) => {
    ipcRenderer.on('schedule:notify', (_event, payload) => callback(payload));
  },
});
