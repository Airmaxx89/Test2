const fileInput = document.getElementById('file-path');
const chooseFileBtn = document.getElementById('choose-file-btn');
const form = document.getElementById('entry-form');
const typeSelect = document.getElementById('type-select');
const dateField = document.getElementById('date-field');
const dateInput = document.getElementById('date-input');
const weekdayField = document.getElementById('weekday-field');
const weekdaySelect = document.getElementById('weekday-select');
const timeInput = document.getElementById('time-input');
const entryList = document.getElementById('entry-list');
const logList = document.getElementById('log-list');

let selectedFilePath = '';

const WEEKDAY_NAMES = ['Sonntag', 'Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag'];
const TYPE_LABELS = { once: 'Einmalig', daily: 'Täglich', weekly: 'Wöchentlich' };

function updateFieldVisibility() {
  const type = typeSelect.value;
  dateField.style.display = type === 'once' ? 'flex' : 'none';
  weekdayField.style.display = type === 'weekly' ? 'flex' : 'none';
}

typeSelect.addEventListener('change', updateFieldVisibility);
updateFieldVisibility();

chooseFileBtn.addEventListener('click', async () => {
  const path = await window.api.chooseFile();
  if (path) {
    selectedFilePath = path;
    fileInput.value = path;
  }
});

function describeSchedule(entry) {
  if (entry.type === 'once') {
    return `Einmalig am ${entry.date} um ${entry.time}${entry.doneOnce ? ' (bereits ausgeführt)' : ''}`;
  }
  if (entry.type === 'daily') {
    return `Täglich um ${entry.time}`;
  }
  if (entry.type === 'weekly') {
    return `Jeden ${WEEKDAY_NAMES[entry.weekday]} um ${entry.time}`;
  }
  return '';
}

function renderEntries(entries) {
  entryList.innerHTML = '';
  if (!entries.length) {
    const li = document.createElement('li');
    li.className = 'empty-hint';
    li.textContent = 'Noch keine Einträge vorhanden.';
    entryList.appendChild(li);
    return;
  }

  for (const entry of entries) {
    const li = document.createElement('li');
    if (!entry.enabled) li.classList.add('disabled');

    const info = document.createElement('div');
    info.className = 'entry-info';

    const pathEl = document.createElement('div');
    pathEl.className = 'path';
    pathEl.textContent = entry.filePath;

    const metaEl = document.createElement('div');
    metaEl.className = 'meta';
    const lastOpened = entry.lastOpened
      ? ` · zuletzt geöffnet: ${new Date(entry.lastOpened).toLocaleString('de-DE')}`
      : '';
    metaEl.textContent = `${describeSchedule(entry)}${lastOpened}`;

    info.appendChild(pathEl);
    info.appendChild(metaEl);

    const actions = document.createElement('div');
    actions.className = 'entry-actions';

    const toggleBtn = document.createElement('button');
    toggleBtn.textContent = entry.enabled ? 'Deaktivieren' : 'Aktivieren';
    toggleBtn.addEventListener('click', async () => {
      const updated = await window.api.toggle(entry.id);
      renderEntries(updated);
    });

    const openBtn = document.createElement('button');
    openBtn.textContent = 'Jetzt öffnen';
    openBtn.addEventListener('click', async () => {
      const updated = await window.api.openNow(entry.id);
      renderEntries(updated);
    });

    const deleteBtn = document.createElement('button');
    deleteBtn.textContent = 'Löschen';
    deleteBtn.className = 'danger';
    deleteBtn.addEventListener('click', async () => {
      const updated = await window.api.remove(entry.id);
      renderEntries(updated);
    });

    actions.appendChild(toggleBtn);
    actions.appendChild(openBtn);
    actions.appendChild(deleteBtn);

    li.appendChild(info);
    li.appendChild(actions);
    entryList.appendChild(li);
  }
}

form.addEventListener('submit', async (event) => {
  event.preventDefault();
  if (!selectedFilePath) {
    alert('Bitte zuerst eine Datei auswählen.');
    return;
  }

  const type = typeSelect.value;
  const time = timeInput.value;
  if (!time) {
    alert('Bitte eine Uhrzeit angeben.');
    return;
  }

  const data = { filePath: selectedFilePath, type, time };

  if (type === 'once') {
    if (!dateInput.value) {
      alert('Bitte ein Datum angeben.');
      return;
    }
    data.date = dateInput.value;
  }

  if (type === 'weekly') {
    data.weekday = Number(weekdaySelect.value);
  }

  const updated = await window.api.add(data);
  renderEntries(updated);

  form.reset();
  selectedFilePath = '';
  fileInput.value = '';
  updateFieldVisibility();
});

window.api.onUpdated((entries) => renderEntries(entries));

window.api.onNotify(({ message, time }) => {
  const li = document.createElement('li');
  const timeSpan = document.createElement('span');
  timeSpan.className = 'log-time';
  timeSpan.textContent = new Date(time).toLocaleTimeString('de-DE');
  li.appendChild(timeSpan);
  li.appendChild(document.createTextNode(message));
  logList.prepend(li);
});

(async () => {
  const entries = await window.api.getAll();
  renderEntries(entries);
})();
