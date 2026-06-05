import { LiveActivity } from 'capacitor-live-activity';
import { FirebaseMessaging } from '@capacitor-firebase/messaging';

const $ = (id) => document.getElementById(id);
const log = (m) => { $('log').textContent += `[${new Date().toLocaleTimeString()}] ${m}\n`; };

const LS = {
  BASE_URL: 'liveactivity.baseurl',
  FCM: 'liveactivity.fcm',
  P2S: 'liveactivity.p2s',
  PUSH: 'liveactivity.push'
};

window.onload = () => {
  $('base-url').value = localStorage.getItem(LS.BASE_URL) || 'http://localhost:3000';
  $('fcm').value = localStorage.getItem(LS.FCM) || '';
  $('p2s').value = localStorage.getItem(LS.P2S) || '';
  $('push').value = localStorage.getItem(LS.PUSH) || '';

  // sinnvolle Defaults
  $('attributes-type').value = 'LiveActivityWidgetExtension.GenericAttributes';
  $('attrs').value = JSON.stringify({ id: 'demo-remote', staticValues: { type: 'delivery', title: '📦 Delivery' } }, null, 2);
  $('content').value = JSON.stringify({ status: 'Starting…', eta: '20 min' }, null, 2);
  $('alert').value = JSON.stringify({ title: 'Live Activity', body: 'Started remotely' }, null, 2);

  $('upd').value = JSON.stringify({ status: 'On the way', eta: '5 min' }, null, 2);
  $('updAlert').value = JSON.stringify({ title: 'Update', body: 'Almost there' }, null, 2);
  $('dismissal-policy').value = 'default';
  $('endState').value = JSON.stringify({ status: 'Delivered', eta: 'Now' }, null, 2);
};

window.clearLog = () => { $('log').textContent = ''; };

window.saveBaseUrl = () => {
  localStorage.setItem(LS.BASE_URL, $('base-url').value.trim());
  log('💾 Saved base URL.');
};

async function ensurePerms() {
  const { receive } = await FirebaseMessaging.requestPermissions();
  if (receive !== 'granted') throw new Error('Notification permission not granted.');
}

window.requestPerms = async () => {
  try { await ensurePerms(); log('✅ Permission granted'); } 
  catch (e) { log('❌ ' + e.message); }
};

window.getFcm = async () => {
  try {
    await ensurePerms();
    const { token } = await FirebaseMessaging.getToken();
    $('fcm').value = token;
    localStorage.setItem(LS.FCM, token);
    log('📬 FCM token acquired.');
  } catch (e) {
    log('❌ getToken failed: ' + e.message);
  }
};

window.observeP2S = async () => {
  try {
    await LiveActivity.observePushToStartToken();
    LiveActivity.addListener('liveActivityPushToStartToken', ({ token }) => {
      $('p2s').value = token;
      localStorage.setItem(LS.P2S, token);
      log('🔑 Push-to-Start token updated.');
    });
    log('👂 Listening for Push-to-Start token…');
  } catch (e) {
    log('❌ observePushToStartToken: ' + e.message);
  }
};

window.observeActivityTokens = async () => {
  try {
    // Event-Name deines Plugins: hier "liveActivityPushToken"
    LiveActivity.addListener('liveActivityPushToken', ({ id, token }) => {
      $('push').value = token;
      localStorage.setItem(LS.PUSH, token);
      log(`🧩 Activity push token for "${id}" received.`);
    });
    // Falls dein Plugin einen Start-Call braucht, der Token-Updates triggert,
    // starte lokal eine Dummy-Activity (optional).
    log('👂 Listening for per-activity push token…');
  } catch (e) {
    log('❌ observeActivityTokens: ' + e.message);
  }
};

window.configureUpdateTokenEndpoint = async () => {
  try {
    await LiveActivity.setUpdateTokenEndpoint({
      url: `${base()}/live-activity/register-token`,
    });
    log('🌐 Native update token endpoint registered.');
  } catch (e) {
    log('❌ configureUpdateTokenEndpoint: ' + e.message);
  }
};

window.loadCachedActivityTokens = async () => {
  try {
    const attrs = JSON.parse($('attrs').value || '{}');
    const id = attrs.id;
    const { items } = await LiveActivity.getActivityPushTokens(id ? { id } : undefined);
    const latest = items.at(-1);
    if (!latest) {
      log('ℹ️ No cached activity push token found.');
      return;
    }

    $('push').value = latest.token;
    localStorage.setItem(LS.PUSH, latest.token);
    log(`📥 Cached activity push token for "${latest.id}" loaded.`);
  } catch (e) {
    log('❌ loadCachedActivityTokens: ' + e.message);
  }
};

function base() { return ( $('base-url').value || '' ).trim(); }
function fcm() { return ( $('fcm').value || '' ).trim(); }
function p2s() { return ( $('p2s').value || '' ).trim(); }
function push() { return ( $('push').value || '' ).trim(); }

async function post(path, body) {
  const url = `${base()}${path}`;
  const res = await fetch(url, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) });
  const json = await res.json();
  if (!res.ok || !json.ok) throw new Error(json.error || `HTTP ${res.status}`);
  return json;
}

window.ping = async () => {
  try {
    const out = await post('/ping', { fcmToken: fcm() });
    log('📡 Ping sent. messageId=' + out.messageId);
  } catch (e) { log('❌ ping: ' + e.message); }
};

window.remoteStart = async () => {
  try {
    const body = {
      fcmToken: fcm(),
      pushToStartToken: p2s(),
      attributesType: $('attributes-type').value.trim() || undefined,
      attributes: JSON.parse($('attrs').value || '{}'),
      contentState: { values: JSON.parse($('content').value || '{}') },
    };
    const alert = $('alert').value.trim(); if (alert) body.alert = JSON.parse(alert);
    const out = await post('/live-activity/start', body);
    log('▶️ Remote start OK. messageId=' + out.messageId);
  } catch (e) { log('❌ remoteStart: ' + e.message); }
};

window.remoteUpdate = async () => {
  try {
    const out = await post('/live-activity/update', {
      fcmToken: fcm(),
      pushToken: push(),
      contentState: { values: JSON.parse($('upd').value || '{}') },
      alert: ($('updAlert').value.trim() ? JSON.parse($('updAlert').value) : undefined),
    });
    log('🔄 Remote update OK. messageId=' + out.messageId);
  } catch (e) { log('❌ remoteUpdate: ' + e.message); }
};

window.remoteEnd = async () => {
  try {
    const dismissalPolicy = $('dismissal-policy').value.trim();
    const dismissal = $('dismissal').value.trim();
    const out = await post('/live-activity/end', {
      fcmToken: fcm(),
      pushToken: push(),
      contentState: ($('endState').value.trim() ? { values: JSON.parse($('endState').value) } : undefined),
      dismissalPolicy: dismissalPolicy || undefined,
      dismissalDate: dismissal ? parseInt(dismissal, 10) : undefined
    });
    log('⏹ Remote end OK. messageId=' + out.messageId);
  } catch (e) { log('❌ remoteEnd: ' + e.message); }
};
