import 'dart:math';

/// Kalimat penyemangat yang muncul acak setiap kali Hanary dibuka.
const kalimatPenyemangat = [
  'Sedikit demi sedikit, lama-lama tugasmu jadi bukit yang berhasil kamu daki.',
  'Kamu nggak harus sempurna, cukup mulai dulu. Langkah pertama itu yang paling berharga.',
  'Deadline bukan musuh, dia cuma pengingat bahwa kamu mampu menyelesaikannya.',
  'Hari ini adalah kesempatan baru untuk jadi versi terbaik dirimu.',
  'Kerjakan satu tugas kecil sekarang, dirimu besok pasti berterima kasih.',
  'Usaha nggak akan mengkhianati hasil. Semangat terus, ya!',
  'Istirahat boleh, menyerah jangan.',
  'Kamu sudah sejauh ini. Sedikit lagi, kamu pasti bisa!',
  'Fokus pada kemajuan, bukan kesempurnaan.',
  'Mimpi besar dimulai dari kebiasaan kecil yang konsisten.',
  'Jangan bandingkan prosesmu dengan orang lain. Setiap orang punya waktunya sendiri.',
  'Yang penting bukan seberapa cepat, tapi kamu terus melangkah.',
  'Tarik napas, minum air, lalu taklukkan tugas hari ini!',
  'Hal sulit hari ini adalah cerita bangga di masa depan.',
  'Belajar memang capek, tapi lebih capek lagi kalau menyesal nanti.',
  'Percaya pada dirimu sendiri. Kamu lebih kuat dari yang kamu kira.',
  'Selesaikan yang dimulai, lalu rayakan dengan bangga.',
  'Setiap tugas yang selesai adalah satu kemenangan kecil. Kumpulkan sebanyak-banyaknya!',
  'Disiplin hari ini, bebas besok.',
  'Kamu hebat karena kamu terus mencoba.',
];

/// Mengambil satu kalimat penyemangat secara acak.
String kalimatAcak([Random? random]) =>
    kalimatPenyemangat[(random ?? Random()).nextInt(kalimatPenyemangat.length)];

/// Salam sesuai jam: pagi, siang, sore, atau malam.
String salamWaktu(DateTime waktu) {
  final jam = waktu.hour;
  if (jam < 4) return 'Selamat malam';
  if (jam < 11) return 'Selamat pagi';
  if (jam < 15) return 'Selamat siang';
  if (jam < 18) return 'Selamat sore';
  return 'Selamat malam';
}
