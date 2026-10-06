// Terjemahan teks bagian "umum". Kunci = teks Bahasa Indonesia di kode;
// nilai = [English, 日本語, 한국어, 中文].
const Map<String, List<String>> kamusUmum = {
  // Salam sesuai jam.
  'Selamat pagi': ['Good morning', 'おはよう', '좋은 아침이에요', '早上好'],
  'Selamat siang': ['Good afternoon', 'こんにちは', '좋은 오후예요', '中午好'],
  'Selamat sore': ['Good afternoon', 'こんにちは', '좋은 오후예요', '下午好'],
  'Selamat malam': ['Good evening', 'こんばんは', '좋은 저녁이에요', '晚上好'],

  // Kalimat penyemangat.
  'Sedikit demi sedikit, lama-lama tugasmu jadi bukit yang berhasil kamu daki.': [
    'Little by little, your pile of tasks becomes a hill you\'ve managed to climb.',
    '少しずつ進めれば、課題の山もいつか登りきれるよ。',
    '조금씩 하다 보면 과제 더미도 어느새 넘어선 언덕이 될 거예요.',
    '一点一点来，作业堆成的小山终会被你翻越。',
  ],
  'Kamu nggak harus sempurna, cukup mulai dulu. Langkah pertama itu yang paling berharga.': [
    'You don\'t have to be perfect, just get started. The first step is the most valuable one.',
    '完璧じゃなくていい、まずは始めよう。最初の一歩がいちばん大切だよ。',
    '완벽하지 않아도 괜찮아요, 일단 시작해 봐요. 첫걸음이 가장 소중하니까요.',
    '不用追求完美，先开始就好。迈出第一步最珍贵。',
  ],
  'Deadline bukan musuh, dia cuma pengingat bahwa kamu mampu menyelesaikannya.': [
    'A deadline isn\'t your enemy, it\'s just a reminder that you can get it done.',
    '締め切りは敵じゃない。やり遂げられるって教えてくれるだけだよ。',
    '마감은 적이 아니에요. 끝낼 수 있다는 걸 알려 주는 알림일 뿐이에요.',
    '截止日期不是敌人，它只是提醒你：你能完成。',
  ],
  'Hari ini adalah kesempatan baru untuk jadi versi terbaik dirimu.': [
    'Today is a new chance to be the best version of yourself.',
    '今日は、最高の自分になる新しいチャンスだよ。',
    '오늘은 최고의 내가 될 새로운 기회예요.',
    '今天是成为更好的自己的新机会。',
  ],
  'Kerjakan satu tugas kecil sekarang, dirimu besok pasti berterima kasih.': [
    'Do one small task now, and tomorrow\'s you will thank you.',
    '今ひとつ小さな課題を片づければ、明日の自分がきっと感謝するよ。',
    '지금 작은 과제 하나만 해 두면 내일의 내가 고마워할 거예요.',
    '现在完成一项小作业，明天的你一定会感谢自己。',
  ],
  'Usaha nggak akan mengkhianati hasil. Semangat terus, ya!': [
    'Hard work never betrays you. Keep it up!',
    '努力は裏切らない。その調子でがんばろう！',
    '노력은 배신하지 않아요. 계속 힘내요!',
    '努力不会白费。继续加油哦！',
  ],
  'Istirahat boleh, menyerah jangan.': [
    'Rest if you need to, but don\'t give up.',
    '休んでもいい、でもあきらめないで。',
    '쉬어도 괜찮지만, 포기는 하지 마요.',
    '可以休息，但别放弃。',
  ],
  'Kamu sudah sejauh ini. Sedikit lagi, kamu pasti bisa!': [
    'You\'ve come this far. Just a little more, you\'ve got this!',
    'ここまで来たんだから、あと少し。きっとできるよ！',
    '여기까지 왔잖아요. 조금만 더, 할 수 있어요!',
    '你已经走了这么远。再坚持一下，你一定行！',
  ],
  'Fokus pada kemajuan, bukan kesempurnaan.': [
    'Focus on progress, not perfection.',
    '完璧より、前に進むことを大切に。',
    '완벽함보다 나아가는 것에 집중해요.',
    '专注于进步，而不是完美。',
  ],
  'Mimpi besar dimulai dari kebiasaan kecil yang konsisten.': [
    'Big dreams start with small, consistent habits.',
    '大きな夢は、小さな習慣の積み重ねから始まるよ。',
    '큰 꿈은 꾸준한 작은 습관에서 시작돼요.',
    '远大的梦想始于坚持不懈的小习惯。',
  ],
  'Jangan bandingkan prosesmu dengan orang lain. Setiap orang punya waktunya sendiri.': [
    'Don\'t compare your journey with others. Everyone has their own timing.',
    '自分のペースを人と比べないで。みんなそれぞれのタイミングがあるよ。',
    '내 과정을 남과 비교하지 마요. 누구에게나 자기만의 때가 있어요.',
    '别拿自己的进度和别人比较。每个人都有自己的节奏。',
  ],
  'Yang penting bukan seberapa cepat, tapi kamu terus melangkah.': [
    'It\'s not about how fast you go, but that you keep moving.',
    '大事なのは速さじゃなくて、歩き続けること。',
    '중요한 건 속도가 아니라 계속 나아가는 거예요.',
    '重要的不是有多快，而是你一直在前进。',
  ],
  'Tarik napas, minum air, lalu taklukkan tugas hari ini!': [
    'Take a breath, drink some water, then conquer today\'s tasks!',
    '深呼吸して、水を飲んで、今日の課題をやっつけよう！',
    '숨 한번 고르고, 물 한 잔 마시고, 오늘의 과제를 정복해요!',
    '深呼吸，喝口水，然后拿下今天的作业！',
  ],
  'Hal sulit hari ini adalah cerita bangga di masa depan.': [
    'Today\'s struggles are tomorrow\'s proud stories.',
    '今日の大変なことは、未来の自慢話になるよ。',
    '오늘의 어려움은 미래의 자랑스러운 이야기가 될 거예요.',
    '今天的困难，会是将来值得骄傲的故事。',
  ],
  'Belajar memang capek, tapi lebih capek lagi kalau menyesal nanti.': [
    'Studying is tiring, but regretting it later is even more tiring.',
    '勉強は疲れるけど、あとで後悔するほうがもっと疲れるよ。',
    '공부는 힘들지만, 나중에 후회하는 건 더 힘들어요.',
    '学习确实累，但以后后悔会更累。',
  ],
  'Percaya pada dirimu sendiri. Kamu lebih kuat dari yang kamu kira.': [
    'Believe in yourself. You\'re stronger than you think.',
    '自分を信じて。あなたは思っているより強いよ。',
    '자신을 믿어요. 생각보다 훨씬 강하니까요.',
    '相信自己。你比想象中更强大。',
  ],
  'Selesaikan yang dimulai, lalu rayakan dengan bangga.': [
    'Finish what you started, then celebrate proudly.',
    '始めたことをやり遂げて、胸を張ってお祝いしよう。',
    '시작한 일을 끝내고, 자랑스럽게 축하해요.',
    '完成你开始的事，然后骄傲地庆祝吧。',
  ],
  'Setiap tugas yang selesai adalah satu kemenangan kecil. Kumpulkan sebanyak-banyaknya!': [
    'Every finished task is a small win. Collect as many as you can!',
    '課題をひとつ終えるたびに小さな勝利。たくさん集めよう！',
    '끝낸 과제 하나하나가 작은 승리예요. 최대한 많이 모아 봐요!',
    '每完成一项作业就是一次小胜利。尽量多收集一些吧！',
  ],
  'Disiplin hari ini, bebas besok.': [
    'Disciplined today, free tomorrow.',
    '今日がんばれば、明日は自由。',
    '오늘의 꾸준함이 내일의 자유예요.',
    '今天自律，明天自由。',
  ],
  'Kamu hebat karena kamu terus mencoba.': [
    'You\'re amazing because you keep trying.',
    'あきらめずに挑戦し続けるあなたはすごいよ。',
    '계속 도전하는 당신은 정말 멋져요.',
    '你很棒，因为你一直在努力尝试。',
  ],

  // Ringkasan pesan.
  'Foto': ['Photo', '写真', '사진', '照片'],
  'Tugas: {judul}': ['Task: {judul}', '課題：{judul}', '과제: {judul}', '作业：{judul}'],
  'Pesan suara ({durasi})': [
    'Voice message ({durasi})',
    'ボイスメッセージ（{durasi}）',
    '음성 메시지 ({durasi})',
    '语音消息（{durasi}）',
  ],

  // Status tugas (StatusTugas.labelTr).
  'Belum': ['Not started', '未着手', '시작 전', '未开始'],
  'Sedang dikerjakan': ['In progress', '取り組み中', '진행 중', '进行中'],
  'Selesai': ['Done', '完了', '완료', '已完成'],

  // Peran (Peran.labelTr / labelTempatTr / labelPosisiTr).
  'Pelajar': ['Student', '学生', '학생', '学生'],
  'Sekolah': ['School', '学校', '학교', '学校'],
  'Kelas': ['Class', 'クラス', '학년/반', '班级'],
  'Mahasiswa': ['University student', '大学生', '대학생', '大学生'],
  'Kampus': ['University', '大学', '대학교', '大学'],
  'Jurusan': ['Major', '学部・学科', '전공', '专业'],
  'Pekerja / kantoran': ['Working / office', '社会人・会社員', '직장인', '上班族'],
  'Perusahaan / instansi': ['Company / organization', '会社・団体', '회사 / 기관', '公司 / 机构'],
  'Jabatan / pekerjaan': ['Position / job', '役職・仕事', '직책 / 직업', '职位 / 工作'],
  'Lainnya': ['Other', 'その他', '기타', '其他'],
  'Tempat / komunitas': ['Place / community', '場所・コミュニティ', '장소 / 커뮤니티', '地点 / 社群'],
  'Keterangan': ['Description', '説明', '설명', '说明'],
  'Sekolah / kampus': ['School / university', '学校・大学', '학교 / 대학교', '学校 / 大学'],
  'Kelas / jurusan': ['Class / major', 'クラス・学科', '학년·반 / 전공', '班级 / 专业'],

  // Tema latar (TemaLatar.namaTr).
  'Samudra': ['Ocean', 'オーシャン', '바다', '海洋'],
  'Hutan': ['Forest', 'フォレスト', '숲', '森林'],
  'Sakura': ['Sakura', 'サクラ', '벚꽃', '樱花'],
  'Senja': ['Sunset', 'サンセット', '노을', '黄昏'],
  'Malam': ['Night', 'ナイト', '밤', '夜晚'],

  // Gerbang masuk & selamat datang.
  'Gagal memuat profil: {error}': [
    'Couldn\'t load profile: {error}',
    'プロフィールを読み込めませんでした：{error}',
    '프로필을 불러오지 못했어요: {error}',
    '无法加载个人资料：{error}',
  ],
  'Keluar': ['Sign out', 'ログアウト', '로그아웃', '退出登录'],
  'Login gagal: {error}': [
    'Sign-in failed: {error}',
    'ログインに失敗しました：{error}',
    '로그인 실패: {error}',
    '登录失败：{error}',
  ],
  'Selamat datang di': ['Welcome to', 'ようこそ', '환영해요', '欢迎来到'],
  'Catat semua tugasmu, atur deadline, dan dapatkan pengingat '
      'sebelum terlambat. Kerjakan bareng teman lewat chat dan grup.': [
    'Keep track of all your tasks, set deadlines, and get reminders before it\'s too late. '
        'Work together with friends through chats and groups.',
    '課題をまとめて記録して、締め切りを設定し、遅れる前にリマインダーを受け取ろう。チャットやグループで友だちと一緒に取り組めるよ。',
    '모든 과제를 기록하고 마감을 정해 늦기 전에 알림을 받아요. 채팅과 그룹으로 친구와 함께 해요.',
    '记录所有作业，设置截止日期，在逾期前收到提醒。还能通过聊天和群组和好友一起完成。',
  ],
  'Catat tugas beserta file atau gambarnya': [
    'Save tasks along with their files or images',
    'ファイルや画像付きで課題を記録',
    '파일이나 이미지와 함께 과제 기록',
    '记录作业及其文件或图片',
  ],
  'Pengingat harian sampai deadline': [
    'Daily reminders until the deadline',
    '締め切りまで毎日リマインド',
    '마감까지 매일 알림',
    '截止前每日提醒',
  ],
  'Chat dengan teman dan buat grup': [
    'Chat with friends and create groups',
    '友だちとチャットしてグループを作成',
    '친구와 채팅하고 그룹 만들기',
    '和好友聊天并创建群组',
  ],
  'Masuk dengan Google': ['Sign in with Google', 'Google でログイン', 'Google로 로그인', '使用 Google 登录'],

  // Layar pembuka.
  'CATAT TUGAS & DEADLINE': ['TRACK TASKS & DEADLINES', '課題と締め切りを記録', '과제 & 마감 기록', '记录作业与截止日期'],
  'Hai, selamat datang!': ['Hi, welcome!', 'こんにちは、ようこそ！', '안녕하세요, 환영해요!', '嗨，欢迎！'],
  'Ketuk untuk lanjut': ['Tap to continue', 'タップして続ける', '탭하여 계속', '轻触继续'],

  // Navigasi utama.
  'Panggilan sudah berakhir.': ['The call has ended.', '通話は終了しました。', '통화가 종료됐어요.', '通话已结束。'],
  'Beranda': ['Home', 'ホーム', '홈', '首页'],
  'Chat': ['Chats', 'チャット', '채팅', '聊天'],
  'Profil': ['Profile', 'プロフィール', '프로필', '个人资料'],

  // Kebijakan privasi.
  'Kebijakan privasi': ['Privacy policy', 'プライバシーポリシー', '개인정보 처리방침', '隐私政策'],
  'Privasimu penting. Berikut data yang dipakai Hanary dan cara kami menjaganya.': [
    'Your privacy matters. Here\'s the data Hanary uses and how we protect it.',
    'あなたのプライバシーは大切です。Hanary が使うデータと、その守り方をまとめました。',
    '당신의 개인정보는 소중해요. Hanary가 사용하는 데이터와 이를 보호하는 방법을 알려 드릴게요.',
    '你的隐私很重要。以下是 Hanary 使用的数据以及我们如何保护它们。',
  ],
  'Data akun dan profil': ['Account and profile data', 'アカウントとプロフィールのデータ', '계정 및 프로필 데이터', '账号与个人资料数据'],
  'Saat kamu masuk dengan Google, Hanary menyimpan email, nama, dan foto akun Google-mu, '
      'serta data profil yang kamu isi (nama lengkap, sebutan, sekolah, kelas, dan bio). '
      'Profil ini bisa dilihat pengguna Hanary lain agar mereka bisa menemukan dan menambahkanmu sebagai teman.': [
    'When you sign in with Google, Hanary stores your Google account email, name, and photo, '
        'plus the profile details you fill in (full name, nickname, school, class, and bio). '
        'Other Hanary users can see this profile so they can find you and add you as a friend.',
    'Google でログインすると、Hanary は Google アカウントのメールアドレス・名前・写真と、'
        'あなたが入力したプロフィール（フルネーム、呼び名、学校、クラス、自己紹介）を保存します。'
        'このプロフィールは他の Hanary ユーザーにも表示され、あなたを見つけて友だちに追加できるようになります。',
    'Google로 로그인하면 Hanary는 Google 계정의 이메일, 이름, 사진과 '
        '직접 입력한 프로필 정보(이름, 닉네임, 학교, 학년/반, 소개)를 저장해요. '
        '다른 Hanary 사용자가 나를 찾아 친구로 추가할 수 있도록 이 프로필이 공개돼요.',
    '当你使用 Google 登录时，Hanary 会保存你 Google 账号的邮箱、姓名和头像，'
        '以及你填写的个人资料（全名、昵称、学校、班级和简介）。'
        '其他 Hanary 用户可以看到这份资料，以便找到你并添加你为好友。',
  ],
  'Tugas dan deadline': ['Tasks and deadlines', '課題と締め切り', '과제와 마감', '作业与截止日期'],
  'Judul, mata pelajaran, catatan, deadline, dan status tugas disimpan di server Firebase (Google) '
      'agar tidak hilang saat ganti HP. Hanya kamu yang bisa membaca tugasmu, kecuali kamu sendiri yang membagikannya.': [
    'Task titles, subjects, notes, deadlines, and statuses are stored on Firebase (Google) servers '
        'so they aren\'t lost when you switch phones. Only you can read your tasks, unless you share them yourself.',
    '課題のタイトル、科目、メモ、締め切り、ステータスは、機種変更しても消えないよう Firebase（Google）のサーバーに保存されます。'
        'あなたが自分で共有しない限り、課題を読めるのはあなただけです。',
    '과제 제목, 과목, 메모, 마감, 상태는 휴대폰을 바꿔도 사라지지 않도록 Firebase(Google) 서버에 저장돼요. '
        '직접 공유하지 않는 한 내 과제는 나만 볼 수 있어요.',
    '作业的标题、科目、备注、截止日期和状态保存在 Firebase（Google）服务器上，换手机也不会丢失。'
        '除非你自己分享，否则只有你能看到你的作业。',
  ],
  'Lampiran di Google Drive': [
    'Attachments on Google Drive',
    'Google ドライブの添付ファイル',
    'Google 드라이브의 첨부파일',
    'Google 云端硬盘中的附件'
  ],
  'Gambar dan file lampiran disimpan di HP-mu dan di Google Drive milikmu sendiri. '
      'Hanary hanya meminta izin "drive.file", artinya Hanary hanya bisa melihat file yang dibuat oleh Hanary, '
      'bukan file lain di Drive-mu. Kamu bisa mencabut izin ini kapan saja di myaccount.google.com/permissions.': [
    'Attached images and files are stored on your phone and in your own Google Drive. '
        'Hanary only asks for the "drive.file" permission, which means it can only see files created by Hanary, '
        'not any other files in your Drive. You can revoke this permission anytime at myaccount.google.com/permissions.',
    '添付した画像やファイルは、あなたのスマホとあなた自身の Google ドライブに保存されます。'
        'Hanary が求めるのは「drive.file」権限だけなので、Hanary が作成したファイルしか見られず、'
        'ドライブ内のほかのファイルにはアクセスできません。この権限は myaccount.google.com/permissions でいつでも取り消せます。',
    '첨부한 이미지와 파일은 내 휴대폰과 내 Google 드라이브에 저장돼요. '
        'Hanary는 "drive.file" 권한만 요청하므로 Hanary가 만든 파일만 볼 수 있고, '
        '드라이브의 다른 파일은 볼 수 없어요. 이 권한은 myaccount.google.com/permissions에서 언제든 해제할 수 있어요.',
    '附件中的图片和文件保存在你的手机和你自己的 Google 云端硬盘中。'
        'Hanary 只申请"drive.file"权限，也就是说它只能看到由 Hanary 创建的文件，'
        '无法看到你云端硬盘里的其他文件。你可以随时在 myaccount.google.com/permissions 撤销此权限。',
  ],
  'Chat terenkripsi': ['Encrypted chats', '暗号化されたチャット', '암호화된 채팅', '加密聊天'],
  'Isi pesan chat dienkripsi end-to-end di HP pengirim sebelum dikirim. Server hanya menyimpan pesan yang '
      'sudah teracak, sehingga pengembang Hanary maupun Google tidak bisa membaca isinya. '
      'Kunci rahasia untuk membuka pesan tersimpan aman di HP-mu.': [
    'Chat messages are end-to-end encrypted on the sender\'s phone before they\'re sent. The server only stores '
        'scrambled messages, so neither Hanary\'s developers nor Google can read them. '
        'The secret key to unlock your messages is stored safely on your phone.',
    'チャットのメッセージは、送信前に送信者のスマホでエンドツーエンド暗号化されます。サーバーには暗号化されたメッセージしか保存されないため、'
        'Hanary の開発者も Google も内容を読むことはできません。'
        'メッセージを開くための秘密鍵は、あなたのスマホに安全に保存されています。',
    '채팅 메시지는 보내기 전에 보내는 사람의 휴대폰에서 종단간 암호화돼요. 서버에는 암호화된 메시지만 저장되므로 '
        'Hanary 개발자도 Google도 내용을 읽을 수 없어요. '
        '메시지를 여는 비밀 키는 내 휴대폰에 안전하게 보관돼요.',
    '聊天消息在发送前会在发送者的手机上进行端到端加密。服务器只保存加密后的消息，'
        '因此 Hanary 的开发者和 Google 都无法读取内容。'
        '用于解锁消息的密钥安全地保存在你的手机上。',
  ],
  'Notifikasi': ['Notifications', '通知', '알림', '通知'],
  'Pengingat deadline dijadwalkan langsung di HP-mu. Kamu bisa mematikan notifikasi kapan saja '
      'lewat pengaturan HP.': [
    'Deadline reminders are scheduled directly on your phone. You can turn off notifications anytime '
        'in your phone settings.',
    '締め切りのリマインダーはあなたのスマホ上で直接スケジュールされます。通知はスマホの設定からいつでもオフにできます。',
    '마감 알림은 내 휴대폰에서 바로 예약돼요. 알림은 휴대폰 설정에서 언제든 끌 수 있어요.',
    '截止提醒直接在你的手机上安排。你可以随时在手机设置中关闭通知。',
  ],
  'Pengaturan tampilan': ['Display settings', '表示設定', '화면 설정', '显示设置'],
  'Pilihan mode gelap/terang dan tema latar hanya disimpan di HP-mu.': [
    'Your dark/light mode and background theme choices are only stored on your phone.',
    'ダーク／ライトモードと背景テーマの設定は、あなたのスマホにだけ保存されます。',
    '다크/라이트 모드와 배경 테마 설정은 내 휴대폰에만 저장돼요.',
    '深色/浅色模式和背景主题的选择只保存在你的手机上。',
  ],
  'Yang tidak kami lakukan': ['What we don\'t do', '私たちがしないこと', '우리가 하지 않는 것', '我们不会做的事'],
  'Hanary tidak menampilkan iklan, tidak menjual data, dan tidak membagikan datamu ke pihak lain '
      'selain layanan Google (Firebase dan Google Drive) yang dibutuhkan agar aplikasi berjalan.': [
    'Hanary doesn\'t show ads, doesn\'t sell data, and doesn\'t share your data with anyone '
        'other than the Google services (Firebase and Google Drive) needed for the app to work.',
    'Hanary は広告を表示せず、データを販売せず、アプリの動作に必要な Google のサービス（Firebase と Google ドライブ）以外に'
        'あなたのデータを共有することはありません。',
    'Hanary는 광고를 표시하지 않고, 데이터를 판매하지 않으며, 앱 작동에 필요한 Google 서비스(Firebase와 Google 드라이브) 외에는 '
        '내 데이터를 다른 곳과 공유하지 않아요.',
    'Hanary 不展示广告、不出售数据，除应用运行所需的 Google 服务（Firebase 和 Google 云端硬盘）外，'
        '不会与任何第三方分享你的数据。',
  ],
  'Menghapus data': ['Deleting data', 'データの削除', '데이터 삭제', '删除数据'],
  'Kamu bisa menghapus tugas dan lampiran kapan saja dari aplikasi. Untuk menghapus akun beserta seluruh '
      'datanya, hubungi pengembang Hanary. Folder lampiran di Google Drive bisa kamu hapus sendiri.': [
    'You can delete tasks and attachments anytime from the app. To delete your account along with all '
        'its data, contact the Hanary developer. You can delete the attachments folder in Google Drive yourself.',
    '課題や添付ファイルはアプリからいつでも削除できます。アカウントとすべてのデータを削除したい場合は、'
        'Hanary の開発者に連絡してください。Google ドライブの添付ファイルフォルダは自分で削除できます。',
    '과제와 첨부파일은 앱에서 언제든 삭제할 수 있어요. 계정과 모든 데이터를 삭제하려면 '
        'Hanary 개발자에게 연락해 주세요. Google 드라이브의 첨부파일 폴더는 직접 삭제할 수 있어요.',
    '你可以随时在应用中删除作业和附件。如需删除账号及其全部数据，'
        '请联系 Hanary 开发者。Google 云端硬盘中的附件文件夹可以自行删除。',
  ],
  'Terakhir diperbarui: 6 Oktober 2026': [
    'Last updated: October 6, 2026',
    '最終更新日：2026年10月6日',
    '최종 업데이트: 2026년 10월 6일',
    '最后更新：2026年10月6日',
  ],
};
