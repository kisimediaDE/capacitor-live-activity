import 'dotenv/config';
import express from 'express';
import admin from 'firebase-admin';
import { z } from 'zod';
import fs from 'node:fs';
import path from 'node:path';
import cors from 'cors';

const PORT = Number(process.env.PORT ?? 3000);
const ATTRIBUTES_TYPE = process.env.ATTRIBUTES_TYPE ?? 'GenericAttributes';

function logHeader(msg: string) {
  console.log('\n' + '='.repeat(50) + `\n${msg}\n` + '='.repeat(50));
}

function logObj(label: string, obj: unknown) {
  console.log(`--- ${label}: ---\n${JSON.stringify(obj, null, 2)}\n`);
}

// ---- Init Firebase Admin (robust) ----
(() => {
  try {
    if (admin.apps.length) return;
    const keyPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
    if (keyPath && fs.existsSync(keyPath)) {
      const serviceAccount = JSON.parse(fs.readFileSync(path.resolve(keyPath), 'utf8'));
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount as admin.ServiceAccount),
        projectId: process.env.GOOGLE_CLOUD_PROJECT || serviceAccount.project_id,
      });
    } else {
      admin.initializeApp();
    }
    logHeader('Firebase Admin SDK init OK');
  } catch (e) {
    console.error('Firebase Admin init failed:', e);
    process.exit(1);
  }
})();

const app = express();
app.use(express.json());
app.use(
  cors({
    origin: true,
    methods: ['GET', 'POST', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  }),
);
app.use((req, res, next) => {
  if (req.method === 'OPTIONS') return res.sendStatus(204);
  next();
});

function buildApsPayload(params: {
  event: 'start' | 'update' | 'end';
  contentState?: Record<string, unknown>;
  attributesType?: string;
  attributes?: Record<string, unknown>;
  alert?: { title?: string; body?: string; sound?: string };
  timestamp?: number; // seconds since epoch
  dismissalDate?: number; // seconds since epoch (for 'end')
}) {
  const {
    event,
    contentState,
    attributesType,
    attributes,
    alert,
    timestamp = Math.floor(Date.now() / 1000),
    dismissalDate,
  } = params;
  const aps: Record<string, unknown> = { timestamp, event };
  if (contentState) aps['content-state'] = contentState;
  if (alert) aps['alert'] = alert;
  if (event === 'start') {
    if (attributesType) aps['attributes-type'] = attributesType;
    if (attributes) aps['attributes'] = attributes;
  }
  if (event === 'end' && typeof dismissalDate === 'number') {
    aps['dismissal-date'] = dismissalDate;
  }
  return aps;
}

async function sendLiveActivityFCM(args: {
  fcmToken: string;
  liveActivityToken: string;
  aps: Record<string, unknown>;
}) {
  const APP_BUNDLE_ID = process.env.APP_BUNDLE_ID!;
  const message: admin.messaging.Message = {
    token: args.fcmToken,
    apns: {
      liveActivityToken: args.liveActivityToken,
      headers: {
        'apns-push-type': 'liveactivity',
        'apns-topic': `${APP_BUNDLE_ID}.push-type.liveactivity`,
        'apns-priority': '10',
      },
      payload: { aps: args.aps },
    },
  };
  logObj('Final FCM message', message);
  try {
    const res = await admin.messaging().send(message);
    logHeader(`FCM SEND SUCCESS: ${res}`);
    return res;
  } catch (err) {
    logHeader('FCM SEND ERROR');
    if (err instanceof Error && err.stack) {
      console.error(err.stack);
    } else {
      console.error(err);
    }
    throw err;
  }
}

const StartSchema = z.object({
  fcmToken: z.string().min(1),
  pushToStartToken: z.string().min(1),
  contentState: z.record(z.string(), z.any()).default({}),
  attributes: z.record(z.string(), z.any()).default({}),
  attributesType: z.string().min(1).optional(),
  alert: z
    .object({
      title: z.string().optional(),
      body: z.string().optional(),
      sound: z.string().optional(),
    })
    .optional(),
  timestamp: z.number().optional(),
});

app.post('/live-activity/start', async (req, res) => {
  logHeader('Live Activity START: new /live-activity/start POST');
  logObj('Incoming req.body', req.body);
  try {
    const data = StartSchema.parse(req.body);
    logObj('Parsed input', data);

    const aps = buildApsPayload({
      event: 'start',
      contentState: data.contentState,
      attributesType: data.attributesType ?? ATTRIBUTES_TYPE,
      attributes: data.attributes,
      alert: data.alert,
      timestamp: data.timestamp,
    });
    logObj('Built FCM aps payload', aps);

    const messageId = await sendLiveActivityFCM({
      fcmToken: data.fcmToken,
      liveActivityToken: data.pushToStartToken,
      aps,
    });

    res.json({ ok: true, messageId });
  } catch (err) {
    logHeader('ERROR in /live-activity/start');
    if (err instanceof Error && err.stack) {
      console.error(err.stack);
      res.status(400).json({ ok: false, error: err.message });
    } else {
      console.error(err);
      res.status(400).json({ ok: false, error: 'Unknown error' });
    }
  }
});

const UpdateSchema = z.object({
  fcmToken: z.string().min(1),
  pushToken: z.string().min(1),
  contentState: z.record(z.string(), z.any()).default({}),
  alert: z
    .object({
      title: z.string().optional(),
      body: z.string().optional(),
      sound: z.string().optional(),
    })
    .optional(),
  timestamp: z.number().optional(),
});

app.post('/live-activity/update', async (req, res) => {
  logHeader('Live Activity UPDATE: new /live-activity/update POST');
  logObj('Incoming req.body', req.body);
  try {
    const data = UpdateSchema.parse(req.body);
    logObj('Parsed input', data);

    const aps = buildApsPayload({
      event: 'update',
      contentState: data.contentState,
      alert: data.alert,
      timestamp: data.timestamp,
    });
    logObj('Built FCM aps payload', aps);

    const messageId = await sendLiveActivityFCM({
      fcmToken: data.fcmToken,
      liveActivityToken: data.pushToken,
      aps,
    });

    res.json({ ok: true, messageId });
  } catch (err) {
    logHeader('ERROR in /live-activity/update');
    if (err instanceof Error && err.stack) {
      console.error(err.stack);
      res.status(400).json({ ok: false, error: err.message });
    } else {
      console.error(err);
      res.status(400).json({ ok: false, error: 'Unknown error' });
    }
  }
});

const EndSchema = z.object({
  fcmToken: z.string().min(1),
  pushToken: z.string().min(1),
  contentState: z.record(z.string(), z.any()).default({}),
  alert: z
    .object({
      title: z.string().optional(),
      body: z.string().optional(),
      sound: z.string().optional(),
    })
    .optional(),
  dismissalDate: z.number().optional(),
  timestamp: z.number().optional(),
});

app.post('/live-activity/end', async (req, res) => {
  logHeader('Live Activity END: new /live-activity/end POST');
  logObj('Incoming req.body', req.body);
  try {
    const data = EndSchema.parse(req.body);
    logObj('Parsed input', data);

    const aps = buildApsPayload({
      event: 'end',
      contentState: data.contentState,
      alert: data.alert,
      timestamp: data.timestamp,
      dismissalDate: data.dismissalDate,
    });
    logObj('Built FCM aps payload', aps);

    const messageId = await sendLiveActivityFCM({
      fcmToken: data.fcmToken,
      liveActivityToken: data.pushToken,
      aps,
    });

    res.json({ ok: true, messageId });
  } catch (err) {
    logHeader('ERROR in /live-activity/end');
    if (err instanceof Error && err.stack) {
      console.error(err.stack);
      res.status(400).json({ ok: false, error: err.message });
    } else {
      console.error(err);
      res.status(400).json({ ok: false, error: 'Unknown error' });
    }
  }
});

app.post('/ping', async (req, res) => {
  logHeader('Ping: new /ping POST');
  logObj('Incoming req.body', req.body);
  try {
    const { fcmToken } = req.body;
    const id = await admin.messaging().send({
      token: fcmToken,
      notification: { title: 'Ping', body: 'FCM works 🎉' },
      apns: {
        headers: { 'apns-push-type': 'alert', 'apns-priority': '10' },
        payload: { aps: { sound: 'default' } },
      },
    });
    logHeader(`FCM SEND SUCCESS: ${id}`);
    res.json({ ok: true, messageId: id });
  } catch (e) {
    logHeader('ERROR in /ping');
    if (e instanceof Error && e.stack) {
      console.error(e.stack);
      res.status(400).json({ ok: false, error: e.message });
    } else {
      console.error(e);
      res.status(400).json({ ok: false, error: 'Unknown error' });
    }
  }
});

app.get('/health', (_req, res) => res.json({ ok: true }));

const HOST = process.env.HOST ?? '0.0.0.0';
app.listen(PORT, HOST, () => {
  logHeader(`Server listening on http://${HOST}:${PORT}`);
});
