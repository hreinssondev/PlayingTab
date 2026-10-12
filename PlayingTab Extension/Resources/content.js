// Tells the background whether audible media is playing in this frame.
// Safari has no tab.audible, so we watch media events ourselves.

const frame = Math.random().toString(36).slice(2);
const media = new Set();

function send(playing) {
  browser.runtime.sendMessage({ frame, playing }).catch(() => {});
}

function report() {
  send([...media].some((m) => m.isConnected && !m.paused && !m.ended && !m.muted && m.volume > 0));
}

// Media events don't bubble, so listen in the capture phase.
for (const type of ["play", "playing", "pause", "ended", "emptied", "volumechange"]) {
  document.addEventListener(type, (e) => {
    if (!(e.target instanceof HTMLMediaElement)) return;
    media.add(e.target);
    report();
  }, true);
}

window.addEventListener("pagehide", () => {
  if (media.size) send(false);
});
