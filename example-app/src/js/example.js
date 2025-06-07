import { LiveActivity } from 'capacitor-live-activity';

const log = (msg) => {
  const el = document.getElementById("log");
  el.textContent += `[${new Date().toLocaleTimeString()}] ${msg}\n`;
};

// Init start-id, start-attributes, start-state
// start-id = demo-activity
// start-attributes = { "title": "Pizza Tracker", "orderId": "42" }
// start-state = { "status": "Preparing", "eta": "20 min" }

window.onload = () => {
  document.getElementById("start-id").value = "demo-activity";
  document.getElementById("start-attributes").value = JSON.stringify(
    { title: "Pizza Tracker", orderId: "42" },
    null, 2
  );
  document.getElementById("start-state").value = JSON.stringify(
    { status: "Preparing", eta: "20 min" },
    null, 2
  );
};

window.clearLog = () => {
  document.getElementById("log").textContent = "";
};

// JSON helper
function parseJSONWithValidation(id) {
  const el = document.getElementById(id);
  const tooltipId = `${id}-tooltip`;
  document.getElementById(tooltipId)?.remove();
  el.classList.remove("invalid");

  try {
    const value = el.value.trim();
    if (!value) return {};
    return JSON.parse(value);
  } catch (err) {
    el.classList.add("invalid");
    const tooltip = document.createElement("div");
    tooltip.className = "tooltip";
    tooltip.id = tooltipId;
    tooltip.innerText = "❗ Invalid JSON";
    el.insertAdjacentElement("afterend", tooltip);
    throw new Error("Invalid JSON in field: " + id);
  }
}

window.startActivity = async () => {
  try {
    const id = document.getElementById("start-id").value;
    const attributes = parseJSONWithValidation("start-attributes");
    const contentState = parseJSONWithValidation("start-state");

    await LiveActivity.startActivity({ id, attributes, contentState });
    log("✅ startActivity successful");
  } catch (err) {
    log("❌ startActivity failed: " + err.message);
  }
};

window.updateActivity = async () => {
  try {
    const id = document.getElementById("update-id").value;
    const contentState = parseJSONWithValidation("update-state");
    const alert = parseJSONWithValidation("update-alert");

    await LiveActivity.updateActivity({ id, contentState, alert });
    log("✅ updateActivity successful");
  } catch (err) {
    log("❌ updateActivity failed: " + err.message);
  }
};

window.endActivity = async () => {
  try {
    const id = document.getElementById("end-id").value;
    const contentState = parseJSONWithValidation("end-state");
    const dismissalDate = document.getElementById("end-dismissal").value;

    await LiveActivity.endActivity({
      id,
      contentState,
      dismissalDate: dismissalDate ? parseInt(dismissalDate) : undefined,
    });
    log("✅ endActivity successful");
  } catch (err) {
    log("❌ endActivity failed: " + err.message);
  }
};

window.checkAvailable = async () => {
  const result = await LiveActivity.isAvailable();
  log("🔍 isAvailable: " + result);
};

window.checkRunning = async () => {
  const id = document.getElementById("status-id").value;
  const result = await LiveActivity.isRunning({ id });
  log("🔍 isRunning: " + result);
};

window.getCurrent = async () => {
    try {
      const id = document.getElementById("status-id").value;
      const result = await LiveActivity.getCurrentActivity(
        id ? { id } : undefined
      );
      log("📦 getCurrentActivity:\n" + JSON.stringify(result, null, 2));
    } catch (err) {
      log("❌ getCurrentActivity failed: " + err.message);
    }
  };