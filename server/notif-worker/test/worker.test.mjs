// Uji server notifikasi tanpa internet: semua layanan Google dipalsukan.
// Jalankan: node --test server/notif-worker/test
import assert from 'node:assert/strict';
import { test } from 'node:test';
import { generateKeyPairSync, createSign } from 'node:crypto';

import worker from '../src/index.js';

const PROJECT = 'hanary-uji';
const google = generateKeyPairSync('rsa', { modulusLength: 2048 });
const akunLayanan = generateKeyPairSync('rsa', { modulusLength: 2048 });
const jwk = { ...google.publicKey.export({ format: 'jwk' }), kid: 'kunci1', alg: 'RS256', use: 'sig' };
const env = {
  FIREBASE_SERVICE_ACCOUNT: JSON.stringify({
    project_id: PROJECT,
    client_email: 'notif@hanary-uji.iam.gserviceaccount.com',
    private_key: akunLayanan.privateKey.export({ format: 'pem', type: 'pkcs8' }),
  }),
};

const b64 = (o) => Buffer.from(JSON.stringify(o)).toString('base64url');
function idToken(uid, ubah = {}) {
  const now = Math.floor(Date.now() / 1000);
  const isi = { aud: PROJECT, iss: `https://securetoken.google.com/${PROJECT}`, sub: uid, iat: now, exp: now + 3600, ...ubah };
  const tanpa = `${b64({ alg: 'RS256', kid: 'kunci1', typ: 'JWT' })}.${b64(isi)}`;
  const ttd = createSign('RSA-SHA256').update(tanpa).sign(google.privateKey).toString('base64url');
  return `${tanpa}.${ttd}`;
}

const str = (s) => ({ stringValue: s });
let db;
let fcm;
globalThis.fetch = async (url, init = {}) => {
  url = String(url);
  const json = (o, status = 200) => new Response(JSON.stringify(o), { status, headers: { 'content-type': 'application/json' } });
  if (url.includes('securetoken@system')) return json({ keys: [jwk] });
  if (url === 'https://oauth2.googleapis.com/token') return json({ access_token: 'akses-palsu', expires_in: 3600 });
  if (url.includes('fcm.googleapis.com')) {
    assert.equal(init.headers.authorization, 'Bearer akses-palsu');
    fcm.push(JSON.parse(init.body).message);
    return json({ name: 'ok' });
  }
  const awal = `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents`;
  if (url === `${awal}:batchGet`) {
    const docs = JSON.parse(init.body).documents;
    return json(docs.map((d) => {
      const p = d.split('/documents/')[1];
      return db[p] ? { found: { fields: db[p] } } : { missing: d };
    }));
  }
  if (url.startsWith(`${awal}/`)) {
    const p = url.slice(awal.length + 1);
    return db[p] ? json({ fields: db[p] }) : json({ error: {} }, 404);
  }
  throw new Error(`fetch tak terduga: ${url}`);
};

function siapkan({ lastSender = 'ani', updatedAt = new Date().toISOString(), status } = {}) {
  fcm = [];
  db = {
    'chats/g1': {
      members: { arrayValue: { values: [str('ani'), str('budi'), str('cici')] } },
      lastSender: str(lastSender),
      updatedAt: { timestampValue: updatedAt },
      ...(status ? { status: str(status) } : {}),
    },
    'fcmTokens/budi': { token: str('token-budi') },
    'fcmTokens/ani': { token: str('token-ani') },
    'panggilan/c1': { dari: str('ani'), chatId: str('g1'), dibuatMs: { integerValue: String(Date.now()) } },
  };
}

function minta(body, token) {
  return worker.fetch(
    new Request('https://hanary-notif.contoh.workers.dev/kirim', {
      method: 'POST',
      headers: { authorization: `Bearer ${token}`, 'content-type': 'application/json' },
      body: JSON.stringify(body),
    }),
    env,
  );
}

test('pesan baru membangunkan anggota lain yang punya token', async () => {
  siapkan();
  const res = await minta({ chatId: 'g1' }, idToken('ani'));
  assert.equal(res.status, 200);
  assert.deepEqual(fcm.map((m) => m.token), ['token-budi']);
  assert.deepEqual(fcm[0].data, { jenis: 'pesan', chatId: 'g1' });
  assert.equal(fcm[0].android.priority, 'HIGH');
  assert.equal(fcm[0].notification, undefined); // isi pesan tidak pernah dikirim
});

test('panggilan membawa id panggilan', async () => {
  siapkan();
  const res = await minta({ chatId: 'g1', jenis: 'panggilan', callId: 'c1' }, idToken('ani'));
  assert.equal(res.status, 200);
  assert.deepEqual(fcm[0].data, { jenis: 'panggilan', chatId: 'g1', callId: 'c1' });
});

test('menolak token palsu, kedaluwarsa, atau untuk proyek lain', async () => {
  siapkan();
  const asli = idToken('ani');
  const palsu = `${asli.split('.').slice(0, 2).join('.')}.${Buffer.from('salah').toString('base64url')}`;
  assert.equal((await minta({ chatId: 'g1' }, palsu)).status, 401);
  assert.equal((await minta({ chatId: 'g1' }, idToken('ani', { exp: 10 }))).status, 401);
  assert.equal((await minta({ chatId: 'g1' }, idToken('ani', { aud: 'proyek-lain' }))).status, 401);
  assert.equal((await minta({ chatId: 'g1' }, 'bukan-token')).status, 401);
  assert.equal(fcm.length, 0);
});

test('bukan anggota chat tidak bisa membangunkan siapa pun', async () => {
  siapkan();
  assert.equal((await minta({ chatId: 'g1' }, idToken('dodi'))).status, 403);
  assert.equal(fcm.length, 0);
});

test('tanpa pesan baru dari pengirim, tidak ada notifikasi', async () => {
  siapkan({ lastSender: 'budi' });
  assert.equal((await minta({ chatId: 'g1' }, idToken('ani'))).status, 409);
  siapkan({ updatedAt: new Date(Date.now() - 10 * 60 * 1000).toISOString() });
  assert.equal((await minta({ chatId: 'g1' }, idToken('ani'))).status, 409);
  assert.equal(fcm.length, 0);
});

test('panggilan orang lain atau chat lain ditolak', async () => {
  siapkan();
  assert.equal((await minta({ chatId: 'g1', jenis: 'panggilan', callId: 'c1' }, idToken('budi'))).status, 409);
  assert.equal((await minta({ chatId: 'g1', jenis: 'panggilan', callId: 'tidakada' }, idToken('ani'))).status, 409);
  assert.equal(fcm.length, 0);
});

test('chat yang ditolak tidak mengirim notifikasi', async () => {
  siapkan({ status: 'ditolak' });
  assert.equal((await minta({ chatId: 'g1' }, idToken('ani'))).status, 200);
  assert.equal(fcm.length, 0);
});

test('data aneh ditolak', async () => {
  siapkan();
  assert.equal((await minta({ chatId: '../users/x' }, idToken('ani'))).status, 400);
  assert.equal((await minta({ chatId: 'g1', jenis: 'panggilan' }, idToken('ani'))).status, 400);
});

function siapkanUndang({ at = new Date().toISOString(), dari = 'ani', status = 'berlangsung' } = {}) {
  siapkan();
  const daftar = (xs) => ({ arrayValue: { values: xs.map(str) } });
  db['panggilan/c9'] = {
    dari: str('budi'),
    chatId: str('p_ani_budi'),
    status: str(status),
    ikut: daftar(['ani', 'budi']),
    anggota: daftar(['ani', 'budi', 'eka']),
  };
  db['panggilanMasuk/eka'] = { callId: str('c9'), dari: str(dari), at: { timestampValue: at } };
  db['fcmTokens/eka'] = { token: str('token-eka') };
}

test('mengajak teman ke panggilan hanya membangunkan orang itu', async () => {
  siapkanUndang();
  const res = await minta({ chatId: 'p_ani_budi', jenis: 'undang', callId: 'c9', ke: 'eka' }, idToken('ani'));
  assert.equal(res.status, 200);
  assert.deepEqual(fcm.map((m) => m.token), ['token-eka']);
  assert.deepEqual(fcm[0].data, { jenis: 'panggilan', chatId: 'p_ani_budi', callId: 'c9' });
});

test('ajakan palsu ditolak', async () => {
  const kirim = (uid, ke = 'eka') => minta({ chatId: 'x', jenis: 'undang', callId: 'c9', ke }, idToken(uid));
  siapkanUndang({ dari: 'budi' });
  assert.equal((await kirim('ani')).status, 409); // tanda "diajak" bukan dari ani
  siapkanUndang({ at: new Date(Date.now() - 5 * 60 * 1000).toISOString() });
  assert.equal((await kirim('ani')).status, 409); // ajakan sudah lama
  siapkanUndang({ status: 'selesai' });
  assert.equal((await kirim('ani')).status, 409); // panggilan sudah selesai
  siapkanUndang();
  assert.equal((await kirim('eka')).status, 409); // eka belum ikut panggilan
  assert.equal((await kirim('ani', 'cici')).status, 409); // cici bukan anggota panggilan
  assert.equal((await minta({ chatId: 'x', jenis: 'undang', callId: 'c9' }, idToken('ani'))).status, 400);
  assert.equal(fcm.length, 0);
});
