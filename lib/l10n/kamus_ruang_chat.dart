// Terjemahan teks bagian "ruang_chat". Kunci = teks Bahasa Indonesia di kode;
// nilai = [English, 日本語, 한국어, 中文].
const Map<String, List<String>> kamusRuangChat = {
  // edit_gambar.dart
  'Atur foto': ['Adjust photo', '写真を調整', '사진 조정', '调整照片'],
  'Edit foto': ['Edit photo', '写真を編集', '사진 편집', '编辑照片'],

  // chat_files.dart, avatar_service.dart
  'Bagian file tidak ditemukan.': [
    'Part of the file is missing.',
    'ファイルの一部が見つかりません。',
    '파일 일부를 찾을 수 없어요.',
    '找不到文件的部分内容。'
  ],
  'File terlalu besar. Maksimal 10 MB per file.': [
    'File is too large. Max 10 MB per file.',
    'ファイルが大きすぎます。1ファイル10MBまでです。',
    '파일이 너무 커요. 파일당 최대 10MB예요.',
    '文件太大了。每个文件最大 10 MB。',
  ],
  'Foto terlalu besar, coba foto lain.': [
    'Photo is too large, try another one.',
    '写真が大きすぎます。別の写真を試してください。',
    '사진이 너무 커요. 다른 사진으로 해 보세요.',
    '照片太大了，换一张试试吧。',
  ],

  // lihat_foto.dart
  '{nama} belum memasang foto profil.': [
    "{nama} hasn't set a profile photo yet.",
    '{nama}さんはまだプロフィール写真を設定していません。',
    '{nama} 님은 아직 프로필 사진이 없어요.',
    '{nama} 还没有设置头像。',
  ],
  'Grup ini belum punya foto.': [
    "This group doesn't have a photo yet.",
    'このグループにはまだ写真がありません。',
    '이 그룹은 아직 사진이 없어요.',
    '这个群组还没有照片。',
  ],
  'Foto tidak bisa dimuat.': ["Couldn't load the photo.", '写真を読み込めませんでした。', '사진을 불러올 수 없어요.', '无法加载照片。'],

  // chat_widgets.dart
  'Online': ['Online', 'オンライン', '온라인', '在线'],
  'Terakhir dilihat hari ini {jam}': [
    'Last seen today at {jam}',
    '最終ログイン 今日 {jam}',
    '오늘 {jam}에 마지막 접속',
    '最后上线 今天 {jam}'
  ],
  'Terakhir dilihat kemarin {jam}': [
    'Last seen yesterday at {jam}',
    '最終ログイン 昨日 {jam}',
    '어제 {jam}에 마지막 접속',
    '最后上线 昨天 {jam}',
  ],
  'Terakhir dilihat {tanggal} {jam}': [
    'Last seen {tanggal} at {jam}',
    '最終ログイン {tanggal} {jam}',
    '{tanggal} {jam}에 마지막 접속',
    '最后上线 {tanggal} {jam}',
  ],
  'Pesan terenkripsi end-to-end. Hanya anggota chat yang bisa membacanya.': [
    'Messages are end-to-end encrypted. Only chat members can read them.',
    'メッセージはエンドツーエンドで暗号化されています。チャットのメンバーだけが読めます。',
    '메시지는 종단간 암호화되어 있어요. 채팅 멤버만 읽을 수 있어요.',
    '消息已端到端加密，只有聊天成员才能查看。',
  ],
  'Batal': ['Cancel', 'キャンセル', '취소', '取消'],
  'Terjadi kesalahan: {error}': [
    'Something went wrong: {error}',
    'エラーが発生しました: {error}',
    '오류가 발생했어요: {error}',
    '出错了：{error}'
  ],

  // pesan_suara.dart
  'Jeda': ['Pause', '一時停止', '일시정지', '暂停'],
  'Putar': ['Play', '再生', '재생', '播放'],
  'Merekam…': ['Recording…', '録音中…', '녹음 중…', '正在录音…'],
  'Kirim pesan suara': ['Send voice message', 'ボイスメッセージを送信', '음성 메시지 보내기', '发送语音消息'],

  // story_widgets.dart
  'Tulis catatan': ['Write a note', 'メモを書く', '메모 쓰기', '写个动态'],
  'Catatanmu': ['Your note', 'あなたのメモ', '내 메모', '我的动态'],
  'Muncul sebagai gelembung di atas fotomu di daftar chat teman selama 24 jam.': [
    "Shows as a bubble above your photo in your friends' chat list for 24 hours.",
    '友だちのチャット一覧で、あなたの写真の上に24時間吹き出しで表示されます。',
    '친구의 채팅 목록에서 내 사진 위에 24시간 동안 말풍선으로 보여요.',
    '会以气泡形式显示在好友聊天列表中你的头像上方，持续 24 小时。',
  ],
  'Lagi ngerjain apa?': ["What are you up to?", '今なにしてる？', '지금 뭐 해요?', '在忙什么呢？'],
  'Hapus': ['Delete', '削除', '삭제', '删除'],
  'Bagikan': ['Share', 'シェア', '공유', '分享'],
  'Hilang dalam {n} jam': ['Disappears in {n} h', 'あと{n}時間で消えます', '{n}시간 후 사라져요', '{n} 小时后消失'],
  'Hilang dalam {n} menit': ['Disappears in {n} min', 'あと{n}分で消えます', '{n}분 후 사라져요', '{n} 分钟后消失'],
  'Membalas catatanmu "{teks}": ': [
    'Replying to your note "{teks}": ',
    'あなたのメモ「{teks}」への返信: ',
    '네 메모 "{teks}"에 답장: ',
    '回复你的动态“{teks}”：',
  ],
  'Balas': ['Reply', '返信', '답장', '回复'],

  // chat_room_screen.dart
  'Izinkan mikrofon untuk mengirim pesan suara.': [
    'Allow microphone access to send voice messages.',
    'ボイスメッセージを送るにはマイクを許可してください。',
    '음성 메시지를 보내려면 마이크를 허용해 주세요.',
    '请允许使用麦克风以发送语音消息。',
  ],
  'Pesan suara ({durasi})': ['Voice message ({durasi})', 'ボイスメッセージ（{durasi}）', '음성 메시지 ({durasi})', '语音消息（{durasi}）'],
  'Galeri': ['Gallery', 'ギャラリー', '갤러리', '相册'],
  'File': ['File', 'ファイル', '파일', '文件'],
  'Tugas': ['Task', '課題', '과제', '作业'],
  'Hapus obrolan ini?': ['Delete this chat?', 'このチャットを削除しますか？', '이 채팅을 삭제할까요?', '删除这个聊天？'],
  'Semua pesan di chat ini akan hilang dari HP-mu. Temanmu tetap bisa melihat pesannya.': [
    'All messages in this chat will be removed from your phone. Your friend can still see them.',
    'このチャットのメッセージはすべてあなたのスマホから消えます。相手は引き続きメッセージを見られます。',
    '이 채팅의 모든 메시지가 내 폰에서 사라져요. 친구는 계속 메시지를 볼 수 있어요.',
    '此聊天中的所有消息都会从你的手机上删除，好友仍然可以看到这些消息。',
  ],
  'Chat tidak tersedia.': ['Chat unavailable.', 'チャットを利用できません。', '채팅을 사용할 수 없어요.', '聊天不可用。'],
  '{n} anggota': ['{n} members', 'メンバー{n}人', '멤버 {n}명', '{n} 位成员'],
  'Lainnya§menu': ['More', 'その他', '더보기', '更多'],
  'Info grup': ['Group info', 'グループ情報', '그룹 정보', '群组信息'],
  'Pesan berbintang': ['Starred messages', 'スター付きメッセージ', '별표 메시지', '星标消息'],
  'Hapus obrolan': ['Delete chat', 'チャットを削除', '채팅 삭제', '删除聊天'],
  'Gagal memuat pesan: {error}': [
    "Couldn't load messages: {error}",
    'メッセージを読み込めませんでした: {error}',
    '메시지를 불러오지 못했어요: {error}',
    '消息加载失败：{error}',
  ],
  'Kalian belum berteman. Terima permintaan pesan ini agar bisa saling membalas?': [
    "You're not friends yet. Accept this message request so you can reply to each other?",
    'まだ友だちではありません。このメッセージリクエストを承認して、やり取りできるようにしますか？',
    '아직 친구가 아니에요. 서로 답장할 수 있도록 이 메시지 요청을 수락할까요?',
    '你们还不是好友。要接受这条消息请求以便互相回复吗？',
  ],
  'Kamu menolak permintaan pesan ini.': [
    'You declined this message request.',
    'このメッセージリクエストを拒否しました。',
    '이 메시지 요청을 거절했어요.',
    '你已拒绝这条消息请求。',
  ],
  'Permintaan pesanmu tidak diterima. Kirim permintaan pertemanan agar bisa chat.': [
    "Your message request wasn't accepted. Send a friend request to chat.",
    'メッセージリクエストは承認されませんでした。チャットするには友だち申請を送ってください。',
    '메시지 요청이 수락되지 않았어요. 채팅하려면 친구 요청을 보내 주세요.',
    '你的消息请求未被接受。发送好友请求后才能聊天。',
  ],
  'Terima sekarang': ['Accept now', '今すぐ承認', '지금 수락', '立即接受'],
  'Permintaan pesan terkirim. Kamu bisa mengirim pesan lagi setelah dia menerimanya.': [
    'Message request sent. You can send more messages once they accept it.',
    'メッセージリクエストを送りました。相手が承認したら、またメッセージを送れます。',
    '메시지 요청을 보냈어요. 상대가 수락하면 다시 메시지를 보낼 수 있어요.',
    '消息请求已发送。对方接受后你才能继续发消息。',
  ],
  'Kalian belum berteman. Kamu hanya bisa mengirim 1 pesan sampai dia menerima permintaanmu.': [
    "You're not friends yet. You can only send 1 message until they accept your request.",
    'まだ友だちではありません。相手がリクエストを承認するまで、送れるメッセージは1件だけです。',
    '아직 친구가 아니에요. 상대가 요청을 수락할 때까지 메시지는 1개만 보낼 수 있어요.',
    '你们还不是好友。在对方接受你的请求前，你只能发送 1 条消息。',
  ],
  'Batal membalas': ['Cancel reply', '返信をやめる', '답장 취소', '取消回复'],
  'Kirim foto, file, atau tugas': [
    'Send a photo, file, or task',
    '写真・ファイル・課題を送る',
    '사진, 파일 또는 과제 보내기',
    '发送照片、文件或作业',
  ],
  'Tulis pesan': ['Message', 'メッセージを入力', '메시지 입력', '输入消息'],
  'Rekam pesan suara': ['Record voice message', 'ボイスメッセージを録音', '음성 메시지 녹음', '录制语音消息'],
  'Kirim': ['Send', '送信', '보내기', '发送'],
  'Hari ini': ['Today', '今日', '오늘', '今天'],
  'Kemarin': ['Yesterday', '昨日', '어제', '昨天'],
  'Mengirim…': ['Sending…', '送信中…', '보내는 중…', '正在发送…'],
  'Salin': ['Copy', 'コピー', '복사', '复制'],
  'Hapus bintang': ['Unstar', 'スターを外す', '별표 해제', '取消星标'],
  'Beri bintang': ['Star', 'スターを付ける', '별표하기', '设为星标'],
  'Lepas sematan': ['Unpin', '固定を解除', '고정 해제', '取消置顶'],
  'Sematkan pesan': ['Pin message', 'メッセージを固定', '메시지 고정', '置顶消息'],
  'Tampil di atas chat untuk semua anggota': [
    'Shows at the top of the chat for all members',
    'メンバー全員のチャット上部に表示されます',
    '모든 멤버의 채팅 상단에 표시돼요',
    '为所有成员显示在聊天顶部',
  ],
  'Hapus untuk saya': ['Delete for me', '自分だけ削除', '나에게서 삭제', '仅为我删除'],
  'Hanya hilang dari HP-mu': ['Only removed from your phone', 'あなたのスマホからだけ消えます', '내 폰에서만 사라져요', '只会从你的手机上删除'],
  'Tarik pesan': ['Unsend message', '送信を取り消す', '메시지 회수', '撤回消息'],
  'Hilang untuk semua orang di chat ini': [
    'Removed for everyone in this chat',
    'このチャットの全員から消えます',
    '이 채팅의 모든 사람에게서 사라져요',
    '为此聊天中的所有人删除',
  ],
  'Pesan disalin': ['Message copied', 'メッセージをコピーしました', '메시지를 복사했어요', '消息已复制'],
  'Tarik pesan ini?': ['Unsend this message?', 'このメッセージの送信を取り消しますか？', '이 메시지를 회수할까요?', '撤回这条消息？'],
  'Pesan akan hilang untuk semua orang di chat ini.': [
    'The message will be removed for everyone in this chat.',
    'このチャットの全員からメッセージが消えます。',
    '이 채팅의 모든 사람에게서 메시지가 사라져요.',
    '这条消息将为此聊天中的所有人删除。',
  ],
  'Tarik': ['Unsend', '取り消す', '회수', '撤回'],
  'Kamu menarik pesan ini': ['You unsent this message', 'メッセージの送信を取り消しました', '메시지를 회수했어요', '你撤回了一条消息'],
  'Pesan ini ditarik': ['This message was unsent', 'このメッセージは取り消されました', '회수된 메시지예요', '此消息已被撤回'],
  'Pesan tidak bisa dibuka': ["Message can't be opened", 'メッセージを開けません', '메시지를 열 수 없어요', '无法打开消息'],
  'Pesan ditarik': ['Message unsent', '取り消されたメッセージ', '회수된 메시지', '消息已撤回'],
  'Pesan itu sudah terlalu lama atau dihapus, jadi tidak bisa dibuka di chat.': [
    'That message is too old or was deleted, so it can\'t be opened in the chat.',
    'このメッセージは古すぎるか削除されたため、チャットで開けません。',
    '이 메시지는 너무 오래되었거나 삭제되어 채팅에서 열 수 없어요.',
    '该消息太久远或已被删除，无法在聊天中打开。',
  ],
  'Pesan disematkan': ['Pinned messages', '固定されたメッセージ', '고정된 메시지', '置顶消息'],
  'Semua pesan disematkan': ['All pinned messages', '固定されたメッセージをすべて表示', '고정된 메시지 모두 보기', '全部置顶消息'],
  'Kamu': ['You', 'あなた', '나', '你'],
  'Gagal memuat foto.\nKetuk untuk coba lagi.': [
    "Couldn't load photo.\nTap to try again.",
    '写真を読み込めませんでした。\nタップして再試行。',
    '사진을 불러오지 못했어요.\n탭해서 다시 시도하세요.',
    '照片加载失败。\n点按重试。',
  ],
  'Buka dengan aplikasi lain': ['Open with another app', '他のアプリで開く', '다른 앱으로 열기', '用其他应用打开'],
  'Tidak ada aplikasi untuk membuka file ini.': [
    'No app available to open this file.',
    'このファイルを開けるアプリがありません。',
    '이 파일을 열 수 있는 앱이 없어요.',
    '没有可以打开此文件的应用。',
  ],
  'Tugas disimpan ke daftar tugasmu': [
    'Task saved to your task list',
    '課題をあなたの課題リストに保存しました',
    '과제를 내 과제 목록에 저장했어요',
    '作业已保存到你的作业列表',
  ],
  'Tugas dibagikan': ['Shared task', '共有された課題', '공유된 과제', '分享的作业'],
  'Tersimpan': ['Saved', '保存済み', '저장됨', '已保存'],
  'Simpan ke tugasku': ['Save to my tasks', '自分の課題に保存', '내 과제에 저장', '保存到我的作业'],
  'Belum ada tugas. Buat tugas dulu di Beranda.': [
    'No tasks yet. Create one on the Home screen first.',
    'まだ課題がありません。まずホームで課題を作成してください。',
    '아직 과제가 없어요. 먼저 홈에서 과제를 만들어 주세요.',
    '还没有作业。先在首页创建一个吧。',
  ],
  'Pilih tugas yang mau dibagikan': ['Choose a task to share', '共有する課題を選んでください', '공유할 과제를 선택하세요', '选择要分享的作业'],
  'Menunggu kunci enkripsi': ['Waiting for encryption key', '暗号化キーを待っています', '암호화 키를 기다리는 중', '正在等待加密密钥'],
  'HP ini belum punya kunci untuk membuka chat ini. Kunci dikirim otomatis saat temanmu membuka aplikasi Hanary. Biarkan halaman ini terbuka atau cek lagi nanti.':
      [
    "This phone doesn't have the key to open this chat yet. It's sent automatically when your friend opens Hanary. Keep this page open or check back later.",
    'このスマホにはまだこのチャットを開くキーがありません。キーは相手がHanaryを開いたときに自動で届きます。このページを開いたままにするか、あとで確認してください。',
    '이 폰에는 아직 이 채팅을 열 키가 없어요. 친구가 Hanary를 열면 키가 자동으로 전송돼요. 이 화면을 열어 두거나 나중에 다시 확인해 주세요.',
    '这台手机还没有打开此聊天的密钥。好友打开 Hanary 时会自动发送密钥。请保持此页面打开，或稍后再来查看。',
  ],
};
