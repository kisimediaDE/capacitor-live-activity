import { LiveActivity } from 'capacitor-live-activity';

const log = (msg) => {
  const el = document.getElementById("log");
  el.textContent += `[${new Date().toLocaleTimeString()}] ${msg}\n`;
};

window.onload = () => {
  const id = "scheduled-game-1";
  const futureTime = Math.floor(Date.now() / 1000) + 120; // 2 minutes from now

  document.getElementById("scheduled-id").value = id;
  document.getElementById("scheduled-attributes").value = JSON.stringify(
    {
      type: "sports",
      homeTeam: "Warriors",
      awayTeam: "Lakers",
      venue: "Chase Center"
    },
    null, 2
  );
  document.getElementById("scheduled-state").value = JSON.stringify(
    {
      status: "Scheduled",
      startTime: new Date(futureTime * 1000).toLocaleTimeString(),
      score: "0-0"
    },
    null, 2
  );
  document.getElementById("scheduled-start").value = futureTime;
  document.getElementById("scheduled-alert").value = JSON.stringify(
    {
      title: "Game Starting Soon! 🏀",
      body: "Warriors vs Lakers begins in 15 minutes",
      sound: "default"
    },
    null, 2
  );

  document.getElementById("update-id").value = id;
  document.getElementById("update-state").value = JSON.stringify(
    {
      status: "Live",
      startTime: new Date().toLocaleTimeString(),
      score: "24-18",
      quarter: "Q1"
    },
    null, 2
  );
  document.getElementById("update-alert").value = JSON.stringify(
    {
      title: "Quarter Update 🏀",
      body: "Warriors leading 24-18 in Q1"
    },
    null, 2
  );

  document.getElementById("end-id").value = id;
  document.getElementById("end-state").value = JSON.stringify(
    {
      status: "Final",
      score: "112-108",
      result: "Warriors Win! 🎉"
    },
    null, 2
  );

  document.getElementById("end-dismissal-policy").value = "";
  document.getElementById("end-dismissal").value = "";
  document.getElementById("status-id").value = id;

  // Setup push token listener
  LiveActivity.addListener('liveActivityPushToken', (event) => {
    log(`🔔 Push Token received for ${event.id}:\n${event.token}`);
  });
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

window.scheduleIn = async (seconds) => {
  try {
    const id = `scheduled-quick-${Date.now()}`;
    const startDate = Math.floor(Date.now() / 1000) + seconds;
    const startTime = new Date(startDate * 1000).toLocaleTimeString();
    
    log(`⏰ Scheduling activity to start in ${seconds} seconds (${startTime})...`);

    const result = await LiveActivity.startActivityScheduled({
      id,
      attributes: {
        type: "sports",
        homeTeam: "Warriors",
        awayTeam: "Lakers"
      },
      contentState: {
        status: "Scheduled",
        startTime: startTime,
        countdown: `Starts in ${seconds}s`
      },
      startDate,
      alertConfiguration: {
        title: "🏀 Game Starting!",
        body: `Warriors vs Lakers is about to begin`,
        sound: "default"
      },
      enablePushToUpdate: false,
      style: "standard"
    });

    log(`✅ Activity scheduled successfully!\nActivity ID: ${result.activityId}\nWill start at: ${startTime}`);
    log(`💡 The activity is now in 'pending' state and will start automatically.`);
  } catch (err) {
    log("❌ scheduleActivity failed: " + err.message);
  }
};

window.scheduleActivity = async () => {
  try {
    const id = document.getElementById("scheduled-id").value;
    const attributes = parseJSONWithValidation("scheduled-attributes");
    const contentState = parseJSONWithValidation("scheduled-state");
    const startDate = parseInt(document.getElementById("scheduled-start").value);
    const alertConfiguration = parseJSONWithValidation("scheduled-alert");
    const enablePushToUpdate = document.getElementById("enable-push").checked;
    const style = document.getElementById("activity-style").value;

    if (!startDate || isNaN(startDate)) {
      throw new Error("Invalid start date. Please provide a UNIX timestamp in seconds.");
    }

    const startTime = new Date(startDate * 1000).toLocaleString();
    log(`⏰ Scheduling activity to start at ${startTime}...`);

    const result = await LiveActivity.startActivityScheduled({
      id,
      attributes,
      contentState,
      startDate,
      alertConfiguration,
      enablePushToUpdate,
      style
    });

    log(`✅ Activity scheduled successfully!\nActivity ID: ${result.activityId}`);
    log(`💡 The activity is now in 'pending' state and will start automatically at ${startTime}.`);
    
    if (enablePushToUpdate) {
      log(`🔔 Push updates enabled. Waiting for push token...`);
    }
  } catch (err) {
    log("❌ scheduleActivity failed: " + err.message);
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

window.listActivities = async () => {
  try {
    const result = await LiveActivity.listActivities();
    log("📋 listActivities:\n" + JSON.stringify(result, null, 2));
  } catch (err) {
    log("❌ listActivities failed: " + err.message);
  }
};
