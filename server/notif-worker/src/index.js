// Server kecil "hanary-notif" (Cloudflare Worker, gratis tanpa kartu).
//
// Tugasnya hanya satu: setelah seseorang mengirim pesan atau memulai
// panggilan, HP-nya memanggil POST /kirim, lalu server ini membangunkan HP
// anggota chat lain lewat Firebase Cloud Messaging (FCM).
//
// - Pengirim dibuktikan dengan token login Firebase (ID token).
// - Server memeriksa pengirim memang anggota chat tersebut.
// - Isi pesan TIDAK pernah dikirim ke sini (tetap terenkripsi di Firestore);
//   yang dikirim ke HP penerima hanya "ada pesan di chat X".
//
// Rahasia FIREBASE_SERVICE_ACCOUNT (isi file JSON kunci akun layanan
// Firebase) dipasang otomatis oleh GitHub Actions
// (.github/workflows/deploy-notif.yml).

const JWK_URL = 'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com';
const SCOPES = 'https://www.googleapis.com/auth/datastore https://www.googleapis.com/auth/firebase.messaging';

// Pesan dianggap baru jika pesan terakhir chat dikirim dalam 2 menit ini.
const BATAS_PESAN_MS = 2 * 60 * 1000;
const BATAS_PANGGILAN_MS = 90 * 1000;

let cacheJwk = null; // { keys, sampai }
let cacheAkses = null; // { token, sampai }

export default {
  async fetch(request, env) {
    if (request.method === 'GET') return teks('Hanary notif aktif', 200);
    if (request.method !== 'POST' || new URL(request.url).pathname !== '/kirim') {
      return teks('Tidak ditemukan', 404);
    }
    try {
      return await kirim(request, env);
    } catch (e) {
      console.error(e);
      return teks('Gagal', 500);
    }
  },
};

function teks(isi, status) {
  return new Response(isi, { status, headers: { 'content-type': 'text/plain; charset=utf-8' } });
}

async function kirim(request, env) {
  const akun = JSON.parse(env.FIREBASE_SERVICE_ACCOUNT || '{}');
  const projectId = akun.project_id;
  if (!projectId) return teks('Server belum diatur', 503);

  const auth = request.headers.get('authorization') || '';
  const idToken = auth.startsWith('Bearer ') ? auth.slice(7) : '';
  const uid = await verifikasiIdToken(idToken, projectId);
  if (!uid) return teks('Belum login', 401);

  let body;
  try {
    body = await request.json();
  } catch {
    return teks('Data salah', 400);
  }
  const chatId = typeof body.chatId === 'string' ? body.chatId : '';
  const jenis = ['panggilan', 'undang'].includes(body.jenis) ? body.jenis : 'pesan';
  const callId = typeof body.callId === 'string' ? body.callId : '';
  const ke = typeof body.ke === 'string' ? body.ke : '';
  const idSah = (x) => /^[A-Za-z0-9_-]{1,200}$/.test(x);
  if (!idSah(chatId)) return teks('Data salah', 400);
  if (jenis !== 'pesan' && !idSah(callId)) return teks('Data salah', 400);
  if (jenis === 'undang' && !idSah(ke)) return teks('Data salah', 400);

  const akses = await tokenAkses(akun);
  const fs = new Firestore(projectId, akses);

  // Mengajak satu orang ke panggilan yang sedang berjalan. Orang yang diajak
  // boleh bukan anggota chat, jadi yang diperiksa adalah panggilannya.
  if (jenis === 'undang') return undang(fs, projectId, akses, uid, callId, ke);

  const chat = await fs.ambil(`chats/${chatId}`);
  if (!chat) return teks('Chat tidak ada', 404);
  const anggota = daftarString(chat.members);
  if (!anggota.includes(uid)) return teks('Bukan anggota', 403);
  if (nilaiString(chat.status) === 'ditolak') return teks('OK', 200);

  // Cegah penyalahgunaan: harus benar-benar ada pesan/panggilan baru dari pengirim.
  const sekarang = Date.now();
  if (jenis === 'pesan') {
    const terakhir = Date.parse(nilaiWaktu(chat.updatedAt) || '');
    if (nilaiString(chat.lastSender) !== uid || !(sekarang - terakhir < BATAS_PESAN_MS)) {
      return teks('Tidak ada pesan baru', 409);
    }
  } else {
    const p = await fs.ambil(`panggilan/${callId}`);
    const dibuat = Number(nilaiAngka(p?.dibuatMs) || 0);
    if (!p || nilaiString(p.dari) !== uid || nilaiString(p.chatId) !== chatId || !(Math.abs(sekarang - dibuat) < BATAS_PANGGILAN_MS)) {
      return teks('Panggilan tidak valid', 409);
    }
  }

  const penerima = anggota.filter((u) => u !== uid);
  const token = await fs.ambilBanyak(penerima.map((u) => `fcmTokens/${u}`));
  const data = { jenis, chatId };
  if (jenis === 'panggilan') data.callId = callId;

  const hasil = await Promise.all(
    token.filter(Boolean).map((t) => kirimFcm(projectId, akses, nilaiString(t.token), data, jenis)),
  );
  return new Response(JSON.stringify({ terkirim: hasil.filter(Boolean).length }), {
    headers: { 'content-type': 'application/json' },
  });
}

async function undang(fs, projectId, akses, uid, callId, ke) {
  const p = await fs.ambil(`panggilan/${callId}`);
  if (!p || nilaiString(p.status) === 'selesai') return teks('Panggilan tidak valid', 409);
  const ikut = daftarString(p.ikut);
  const anggota = daftarString(p.anggota);
  if (!ikut.includes(uid) || !anggota.includes(ke) || ke === uid) return teks('Panggilan tidak valid', 409);
  // Harus ada tanda "diajak" baru dari pengirim untuk orang itu.
  const ping = await fs.ambil(`panggilanMasuk/${ke}`);
  const at = Date.parse(nilaiWaktu(ping?.at) || '');
  if (!ping || nilaiString(ping.callId) !== callId || nilaiString(ping.dari) !== uid || !(Date.now() - at < BATAS_PANGGILAN_MS)) {
    return teks('Panggilan tidak valid', 409);
  }
  const [token] = await fs.ambilBanyak([`fcmTokens/${ke}`]);
  const data = { jenis: 'panggilan', chatId: nilaiString(p.chatId), callId };
  const ok = token ? await kirimFcm(projectId, akses, nilaiString(token.token), data, 'panggilan') : false;
  return new Response(JSON.stringify({ terkirim: ok ? 1 : 0 }), {
    headers: { 'content-type': 'application/json' },
  });
}

async function kirimFcm(projectId, akses, token, data, jenis) {
  if (!token) return false;
  const res = await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
    method: 'POST',
    headers: { authorization: `Bearer ${akses}`, 'content-type': 'application/json' },
    body: JSON.stringify({
      message: {
        token,
        data,
        android: { priority: 'HIGH', ttl: jenis === 'panggilan' ? '45s' : '86400s' },
      },
    }),
  });
  if (!res.ok) console.log('FCM gagal', res.status, await res.text());
  return res.ok;
}

// ---------- Firestore REST ----------

class Firestore {
  constructor(projectId, akses) {
    this.dasar = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents`;
    this.nama = `projects/${projectId}/databases/(default)/documents`;
    this.akses = akses;
  }

  async ambil(path) {
    const res = await fetch(`${this.dasar}/${path}`, { headers: { authorization: `Bearer ${this.akses}` } });
    if (res.status === 404) return null;
    if (!res.ok) throw new Error(`Firestore ${res.status}: ${await res.text()}`);
    return (await res.json()).fields || {};
  }

  async ambilBanyak(paths) {
    if (paths.length === 0) return [];
    const res = await fetch(`${this.dasar}:batchGet`, {
      method: 'POST',
      headers: { authorization: `Bearer ${this.akses}`, 'content-type': 'application/json' },
      body: JSON.stringify({ documents: paths.map((p) => `${this.nama}/${p}`) }),
    });
    if (!res.ok) throw new Error(`Firestore ${res.status}: ${await res.text()}`);
    const hasil = await res.json();
    return hasil.map((h) => (h.found ? h.found.fields || {} : null));
  }
}

function nilaiString(v) {
  return v && typeof v.stringValue === 'string' ? v.stringValue : '';
}
function nilaiWaktu(v) {
  return v && typeof v.timestampValue === 'string' ? v.timestampValue : '';
}
function nilaiAngka(v) {
  if (!v) return null;
  return v.integerValue ?? v.doubleValue ?? null;
}
function daftarString(v) {
  const isi = v && v.arrayValue && v.arrayValue.values;
  return Array.isArray(isi) ? isi.map(nilaiString).filter(Boolean) : [];
}

// ---------- Token ----------

function b64urlKeBytes(s) {
  const b64 = s.replace(/-/g, '+').replace(/_/g, '/') + '==='.slice((s.length + 3) % 4);
  const bin = atob(b64);
  const out = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
  return out;
}

function bytesKeB64url(bytes) {
  let bin = '';
  for (const b of new Uint8Array(bytes)) bin += String.fromCharCode(b);
  return btoa(bin).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

function jsonB64url(obj) {
  return bytesKeB64url(new TextEncoder().encode(JSON.stringify(obj)));
}

async function kunciPublikGoogle() {
  if (cacheJwk && cacheJwk.sampai > Date.now()) return cacheJwk.keys;
  const res = await fetch(JWK_URL);
  if (!res.ok) throw new Error(`JWK ${res.status}`);
  const umur = /max-age=(\d+)/.exec(res.headers.get('cache-control') || '');
  const keys = (await res.json()).keys || [];
  cacheJwk = { keys, sampai: Date.now() + (umur ? Number(umur[1]) * 1000 : 3600_000) };
  return keys;
}

/** Memeriksa ID token Firebase. Mengembalikan uid, atau null jika tidak sah. */
export async function verifikasiIdToken(token, projectId, sekarangDetik = Math.floor(Date.now() / 1000)) {
  const bagian = (token || '').split('.');
  if (bagian.length !== 3) return null;
  let header;
  let isi;
  try {
    header = JSON.parse(new TextDecoder().decode(b64urlKeBytes(bagian[0])));
    isi = JSON.parse(new TextDecoder().decode(b64urlKeBytes(bagian[1])));
  } catch {
    return null;
  }
  if (header.alg !== 'RS256' || !header.kid) return null;
  const jwk = (await kunciPublikGoogle()).find((k) => k.kid === header.kid);
  if (!jwk) return null;
  const kunci = await crypto.subtle.importKey(
    'jwk',
    { kty: jwk.kty, n: jwk.n, e: jwk.e, alg: 'RS256', ext: true },
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['verify'],
  );
  const sah = await crypto.subtle.verify(
    'RSASSA-PKCS1-v1_5',
    kunci,
    b64urlKeBytes(bagian[2]),
    new TextEncoder().encode(`${bagian[0]}.${bagian[1]}`),
  );
  if (!sah) return null;
  if (isi.aud !== projectId) return null;
  if (isi.iss !== `https://securetoken.google.com/${projectId}`) return null;
  if (typeof isi.exp !== 'number' || isi.exp < sekarangDetik) return null;
  if (typeof isi.iat !== 'number' || isi.iat > sekarangDetik + 300) return null;
  if (typeof isi.sub !== 'string' || isi.sub.length === 0 || isi.sub.length > 128) return null;
  return isi.sub;
}

function pemKeBytes(pem) {
  const b64 = pem.replace(/-----[^-]+-----/g, '').replace(/\s+/g, '');
  const bin = atob(b64);
  const out = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
  return out;
}

/** Token akses Google untuk Firestore dan FCM dari akun layanan. */
async function tokenAkses(akun) {
  if (cacheAkses && cacheAkses.sampai > Date.now()) return cacheAkses.token;
  const sekarang = Math.floor(Date.now() / 1000);
  const tanpaTtd = `${jsonB64url({ alg: 'RS256', typ: 'JWT' })}.${jsonB64url({
    iss: akun.client_email,
    scope: SCOPES,
    aud: 'https://oauth2.googleapis.com/token',
    iat: sekarang,
    exp: sekarang + 3600,
  })}`;
  const kunci = await crypto.subtle.importKey(
    'pkcs8',
    pemKeBytes(akun.private_key),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const ttd = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', kunci, new TextEncoder().encode(tanpaTtd));
  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: `${tanpaTtd}.${bytesKeB64url(ttd)}`,
    }),
  });
  if (!res.ok) throw new Error(`Token Google ${res.status}: ${await res.text()}`);
  const j = await res.json();
  cacheAkses = { token: j.access_token, sampai: Date.now() + (Number(j.expires_in) - 300) * 1000 };
  return cacheAkses.token;
}
