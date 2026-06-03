import { LiveActivity } from 'capacitor-live-activity';

const log = (msg) => {
  const el = document.getElementById("log");
  el.textContent += `[${new Date().toLocaleTimeString()}] ${msg}\n`;
};

window.onload = () => {
  const id = "eggtimer-soft-1";

  document.getElementById("start-id").value = id;
  document.getElementById("start-attributes").value = JSON.stringify(
    {
      type: "eggtimer",
      level: "soft",
      title: "🥚 Soft Egg Timer"
    },
    null, 2
  );
  document.getElementById("start-state").value = JSON.stringify(
    {
      remaining: "4:00",
      stage: "Start"
    },
    null, 2
  );

  document.getElementById("update-id").value = id;
  document.getElementById("update-state").value = JSON.stringify(
    {
      remaining: "2:30",
      stage: "Cooking"
    },
    null, 2
  );
  document.getElementById("update-alert").value = JSON.stringify(
    {
      title: "Half time!",
      body: "2:30 left for your egg"
    },
    null, 2
  );

  document.getElementById("end-id").value = id;
  document.getElementById("end-state").value = JSON.stringify(
    {
      remaining: "00:00",
      stage: "Readys!"
    },
    null, 2
  );

  document.getElementById("end-dismissal-policy").value = "default";
  document.getElementById("end-dismissal").value = "";
  document.getElementById("status-id").value = id;
};

window.clearLog = () => {
  document.getElementById("log").textContent = "";
};

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
    const dismissalPolicy = document.getElementById("end-dismissal-policy").value;
    const dismissalDate = document.getElementById("end-dismissal").value;

    await LiveActivity.endActivity({
      id,
      contentState,
      dismissalPolicy: dismissalPolicy || undefined,
      dismissalDate: dismissalDate ? parseInt(dismissalDate) : undefined,
    });
    log("✅ endActivity successful");
  } catch (err) {
    log("❌ endActivity failed: " + err.message);
  }
};

window.checkAvailable = async () => {
  const result = await LiveActivity.isAvailable();
  log("🔍 isAvailable: " + JSON.stringify(result, null, 2));
};

window.checkRunning = async () => {
  const id = document.getElementById("status-id").value;
  const result = await LiveActivity.isRunning({ id });
  log("🔍 isRunning: " + JSON.stringify(result, null, 2));
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
