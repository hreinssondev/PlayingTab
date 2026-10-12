// tabs[tabId] = { frames: ids of frames playing media, lastPlay: ms }
//
// The shortcut goes to the playing tab that started most recently; pressing
// it again cycles through the other playing tabs. With nothing playing it
// goes to the tab that played last.

const store = browser.storage.session ?? browser.storage.local;

let state = null;
let queue = Promise.resolve();

// Serialize all event handling so async handlers never interleave.
function run(fn) {
  queue = queue.then(async () => {
    if (!state) state = (await store.get("tabs")).tabs ?? {};
    await fn(state);
    await store.set({ tabs: state });
  }).catch((e) => console.error(e));
  return queue;
}

browser.runtime.onMessage.addListener((msg, sender) => {
  const tabId = sender.tab?.id;
  if (tabId == null || typeof msg?.playing !== "boolean") return;
  run((s) => {
    if (!msg.playing && !s[tabId]) return;
    const t = (s[tabId] ??= { frames: [], lastPlay: 0 });
    t.frames = t.frames.filter((f) => f !== msg.frame);
    if (msg.playing) {
      t.frames.push(msg.frame);
      t.lastPlay = Date.now();
    }
  });
});

browser.tabs.onRemoved.addListener((tabId) => run((s) => {
  delete s[tabId];
}));

browser.commands.onCommand.addListener((command) => run(async (s) => {
  if (command !== "go-to-playing") return;

  const ids = Object.keys(s).map(Number).sort((a, b) => s[b].lastPlay - s[a].lastPlay);
  const playing = ids.filter((id) => s[id].frames.length);
  const pool = playing.length ? playing : ids.slice(0, 1);

  const [active] = await browser.tabs.query({ active: true, lastFocusedWindow: true });
  const start = pool.indexOf(active?.id) + 1;

  // Skip over tabs that no longer exist.
  for (let i = 0; i < pool.length; i++) {
    const id = pool[(start + i) % pool.length];
    try {
      const tab = await browser.tabs.get(id);
      await browser.tabs.update(id, { active: true });
      await browser.windows.update(tab.windowId, { focused: true });
      return;
    } catch {
      delete s[id];
    }
  }
}));

// Tab ids don't survive a restart.
browser.runtime.onStartup.addListener(() => run((s) => {
  for (const k of Object.keys(s)) delete s[k];
}));
