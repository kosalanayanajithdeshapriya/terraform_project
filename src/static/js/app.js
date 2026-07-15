const pill = document.getElementById("live-pill");
const label = document.getElementById("live-label");
const clock = document.getElementById("footer-clock");

async function checkStatus() {
  const started = performance.now();
  try {
    const res = await fetch("/status", { cache: "no-store" });
    const ms = Math.round(performance.now() - started);
    if (!res.ok) throw new Error(String(res.status));
    pill.className = "pill pill-live";
    label.textContent = `live · ${ms}ms`;
  } catch (err) {
    pill.className = "pill pill-down";
    label.textContent = "unreachable";
  }
}

function tickClock() {
  clock.textContent = new Date().toISOString().replace("T", " ").slice(0, 19) + " UTC";
}

checkStatus();
tickClock();
setInterval(checkStatus, 8000);
setInterval(tickClock, 1000);
