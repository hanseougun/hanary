// Terjemahan teks bagian "daftar_chat". Kunci = teks Bahasa Indonesia di kode;
// nilai = [English, 日本語, 한국어, 中文].
const Map<String, List<String>> kamusDaftarChat = {
  // Tab Chat
  'Tambah teman': ['Add friends', '友だちを追加', '친구 추가', '添加好友'],
  'Pengaturan chat & privasi': ['Chat & privacy settings', 'チャットとプライバシーの設定', '채팅 및 개인정보 설정', '聊天与隐私设置'],
  'Obrolan': ['Chats', 'トーク', '대화', '对话'],
  'Panggilan': ['Calls', '通話', '통화', '通话'],
  'Teman': ['Friends', '友だち', '친구', '好友'],
  'Grup baru': ['New group', '新しいグループ', '새 그룹', '新建群组'],
  'Sematkan di atas': ['Pin to top', '上部に固定', '맨 위에 고정', '置顶'],
  'Keluarkan dari arsip': ['Unarchive', 'アーカイブから戻す', '보관 해제', '取消归档'],
  'Arsipkan chat': ['Archive chat', 'チャットをアーカイブ', '채팅 보관', '归档聊天'],
  'Semua pesan di chat ini hilang dari HP-mu': [
    'All messages in this chat will be removed from your phone',
    'このチャットのメッセージがすべてスマホから消えます',
    '이 채팅의 모든 메시지가 내 폰에서 사라져요',
    '此聊天中的所有消息将从你的手机上删除',
  ],
  'Chat dikeluarkan dari arsip': ['Chat unarchived', 'チャットをアーカイブから戻しました', '채팅을 보관함에서 꺼냈어요', '已取消归档聊天'],
  'Chat diarsipkan': ['Chat archived', 'チャットをアーカイブしました', '채팅을 보관했어요', '聊天已归档'],
  'Semua pesan di chat ini akan hilang dari daftarmu. Temanmu tetap bisa melihat pesannya. '
      'Chat akan muncul lagi jika ada pesan baru.': [
    'All messages in this chat will disappear from your list. Your friend can still see them. '
        'The chat will come back if there is a new message.',
    'このチャットのメッセージはあなたの一覧から消えます。相手は引き続きメッセージを見られます。'
        '新しいメッセージが届くとチャットは再び表示されます。',
    '이 채팅의 모든 메시지가 내 목록에서 사라져요. 친구는 계속 메시지를 볼 수 있어요. '
        '새 메시지가 오면 채팅이 다시 나타나요.',
    '此聊天中的所有消息将从你的列表中消失，好友仍然可以看到这些消息。有新消息时，聊天会再次出现。',
  ],
  'Gagal memuat chat: {galat}': [
    'Couldn\'t load chats: {galat}',
    'チャットを読み込めませんでした: {galat}',
    '채팅을 불러오지 못했어요: {galat}',
    '无法加载聊天：{galat}'
  ],
  'Permintaan pesan': ['Message requests', 'メッセージリクエスト', '메시지 요청', '消息请求'],
  '{jumlah} orang yang belum berteman ingin mengirim pesan': [
    '{jumlah} people you\'re not friends with want to message you',
    '友だちではない{jumlah}人がメッセージを送りたがっています',
    '친구가 아닌 {jumlah}명이 메시지를 보내고 싶어 해요',
    '{jumlah} 位非好友想给你发消息',
  ],
  'Diarsipkan': ['Archived', 'アーカイブ済み', '보관됨', '已归档'],
  'Belum ada obrolan': ['No chats yet', 'まだトークがありません', '아직 대화가 없어요', '还没有对话'],
  'Tambah teman di tab Teman, lalu ketuk namanya untuk mulai chat.': [
    'Add friends in the Friends tab, then tap a name to start chatting.',
    '「友だち」タブで友だちを追加して、名前をタップするとチャットを始められます。',
    '친구 탭에서 친구를 추가한 뒤 이름을 눌러 채팅을 시작하세요.',
    '在“好友”标签页添加好友，然后点按名字即可开始聊天。',
  ],
  'Tidak ada chat yang diarsipkan': ['No archived chats', 'アーカイブしたチャットはありません', '보관한 채팅이 없어요', '没有已归档的聊天'],
  'Tekan lama sebuah chat di daftar Obrolan, lalu pilih Arsipkan chat.': [
    'Long-press a chat in the Chats list, then choose Archive chat.',
    '「トーク」一覧でチャットを長押しして、「チャットをアーカイブ」を選んでください。',
    '대화 목록에서 채팅을 길게 누른 뒤 채팅 보관을 선택하세요.',
    '在“对话”列表中长按某个聊天，然后选择“归档聊天”。',
  ],
  'Chat yang diarsipkan tetap di sini walau ada pesan baru. '
      'Tekan lama untuk mengeluarkannya.': [
    'Archived chats stay here even when new messages arrive. Long-press to unarchive.',
    'アーカイブしたチャットは新しいメッセージが届いてもここに残ります。長押しで戻せます。',
    '보관한 채팅은 새 메시지가 와도 여기에 남아 있어요. 길게 눌러 보관을 해제하세요.',
    '已归档的聊天即使收到新消息也会留在这里。长按即可取消归档。',
  ],
  'Tidak ada permintaan': ['No requests', 'リクエストはありません', '요청이 없어요', '没有请求'],
  'Pesan dari orang yang belum berteman denganmu akan muncul di sini.': [
    'Messages from people who aren\'t your friends will show up here.',
    '友だちではない人からのメッセージはここに表示されます。',
    '친구가 아닌 사람이 보낸 메시지는 여기에 표시돼요.',
    '非好友发来的消息会显示在这里。',
  ],
  'Orang yang belum berteman hanya bisa mengirim 1 pesan. Buka pesannya lalu pilih '
      'Terima agar bisa saling membalas, atau Tolak.': [
    'People who aren\'t your friends can only send 1 message. Open it and choose Accept so you can '
        'reply to each other, or Decline.',
    '友だちではない人は1通だけメッセージを送れます。メッセージを開いて「承認」を選ぶとやり取りでき、'
        '「拒否」も選べます。',
    '친구가 아닌 사람은 메시지를 1개만 보낼 수 있어요. 메시지를 열고 수락을 누르면 서로 답장할 수 있고, '
        '거절할 수도 있어요.',
    '非好友只能发送 1 条消息。打开消息后选择“接受”即可互相回复，也可以选择“拒绝”。',
  ],
  'Sudah ditolak': ['Declined', '拒否済み', '거절함', '已拒绝'],
  'Menunggu diterima': ['Waiting to be accepted', '承認待ち', '수락 대기 중', '等待接受'],
  'Belum ada pesan': ['No messages yet', 'まだメッセージがありません', '아직 메시지가 없어요', '还没有消息'],
  'Kamu menarik pesan': ['You unsent a message', 'メッセージの送信を取り消しました', '메시지를 취소했어요', '你撤回了一条消息'],
  'Pesan terenkripsi': ['Encrypted message', '暗号化されたメッセージ', '암호화된 메시지', '加密消息'],
  'Kamu: {teks}': ['You: {teks}', 'あなた: {teks}', '나: {teks}', '你：{teks}'],
  'Draf: ': ['Draft: ', '下書き: ', '임시저장: ', '草稿：'],
  'Hapus dari daftar teman?': ['Remove from friends?', '友だちから削除しますか？', '친구 목록에서 삭제할까요?', '从好友列表中删除？'],
  'Gagal memuat teman: {galat}': [
    'Couldn\'t load friends: {galat}',
    '友だちを読み込めませんでした: {galat}',
    '친구를 불러오지 못했어요: {galat}',
    '无法加载好友：{galat}'
  ],
  'Belum ada teman': ['No friends yet', 'まだ友だちがいません', '아직 친구가 없어요', '还没有好友'],
  'Ketuk ikon tambah teman di kanan atas, lalu cari sebutan atau email temanmu.': [
    'Tap the add-friend icon at the top right, then search for your friend\'s nickname or email.',
    '右上の友だち追加アイコンをタップして、友だちの呼び名かメールアドレスで検索してください。',
    '오른쪽 위의 친구 추가 아이콘을 누른 뒤 친구의 별명이나 이메일을 검색하세요.',
    '点按右上角的添加好友图标，然后搜索好友的昵称或邮箱。',
  ],
  'Permintaan pertemanan': ['Friend requests', '友だちリクエスト', '친구 요청', '好友请求'],
  'Tolak': ['Decline', '拒否', '거절', '拒绝'],
  'Terima': ['Accept', '承認', '수락', '接受'],
  'Teman ({jumlah})': ['Friends ({jumlah})', '友だち ({jumlah})', '친구 ({jumlah})', '好友（{jumlah}）'],

  // Tambah teman
  'Username, sebutan, atau email teman': [
    'Friend\'s username, nickname, or email',
    '友だちのユーザー名、呼び名、またはメールアドレス',
    '친구의 사용자 이름, 별명 또는 이메일',
    '好友的用户名、昵称或邮箱',
  ],
  'Ketik sebutan temanmu (mis. "Gun") atau alamat email Google-nya. '
      'Ketuk nama seseorang untuk mengirim pesan, walau belum berteman.': [
    'Type your friend\'s nickname (e.g. "Gun") or their Google email address. '
        'Tap someone\'s name to message them, even if you\'re not friends yet.',
    '友だちの呼び名（例: "Gun"）か Google のメールアドレスを入力してください。'
        '名前をタップすると、友だちでなくてもメッセージを送れます。',
    '친구의 별명(예: "Gun")이나 구글 이메일 주소를 입력하세요. '
        '이름을 누르면 아직 친구가 아니어도 메시지를 보낼 수 있어요.',
    '输入好友的昵称（例如 "Gun"）或其 Google 邮箱地址。点按某人的名字即可发消息，即使还不是好友。',
  ],
  'Gagal mencari: {galat}': ['Search failed: {galat}', '検索できませんでした: {galat}', '검색하지 못했어요: {galat}', '搜索失败：{galat}'],
  'Tidak ditemukan.': ['No results.', '見つかりませんでした。', '찾을 수 없어요.', '未找到。'],
  'Batalkan': ['Cancel', '取り消す', '취소', '撤销'],
  'Tambah': ['Add', '追加', '추가', '添加'],

  // Grup baru
  'Isi nama grup dulu.': ['Enter a group name first.', '先にグループ名を入力してください。', '먼저 그룹 이름을 입력하세요.', '请先填写群组名称。'],
  'Tambah anggota': ['Add members', 'メンバーを追加', '멤버 추가', '添加成员'],
  'Nama grup': ['Group name', 'グループ名', '그룹 이름', '群组名称'],
  'mis. Kelompok Biologi': ['e.g. Biology Group', '例: 生物グループ', '예: 생물 모둠', '例如：生物小组'],
  'Deskripsi grup (boleh dikosongkan)': [
    'Group description (optional)',
    'グループの説明（任意）',
    '그룹 설명 (선택)',
    '群组简介（可不填）',
  ],
  'Pilih teman': ['Choose friends', '友だちを選ぶ', '친구 선택', '选择好友'],
  'Belum ada teman yang bisa dipilih. Tambah teman dulu dari tab Chat.': [
    'No friends to choose yet. Add friends from the Chat tab first.',
    '選べる友だちがまだいません。先に「チャット」タブから友だちを追加してください。',
    '아직 선택할 친구가 없어요. 먼저 채팅 탭에서 친구를 추가하세요.',
    '还没有可选择的好友。请先在“聊天”标签页添加好友。',
  ],
  'Tambahkan ({jumlah})': ['Add ({jumlah})', '追加 ({jumlah})', '추가 ({jumlah})', '添加（{jumlah}）'],
  'Buat grup ({jumlah} anggota)': [
    'Create group ({jumlah} members)',
    'グループを作成（{jumlah}人）',
    '그룹 만들기 (멤버 {jumlah}명)',
    '创建群组（{jumlah} 名成员）',
  ],

  // Info grup
  'Lihat foto': ['View photo', '写真を見る', '사진 보기', '查看照片'],
  'Ganti foto': ['Change photo', '写真を変更', '사진 변경', '更换照片'],
  'Deskripsi grup': ['Group description', 'グループの説明', '그룹 설명', '群组简介'],
  'mis. Grup diskusi tugas kelompok': [
    'e.g. Group project discussion',
    '例: グループ課題の相談用',
    '예: 모둠 과제 토론방',
    '例如：小组作业讨论群',
  ],
  'Lihat profil': ['View profile', 'プロフィールを見る', '프로필 보기', '查看资料'],
  'Jadikan pemilik grup': ['Make group owner', 'グループのオーナーにする', '그룹 소유자로 지정', '设为群主'],
  'Kamu tidak lagi menjadi pemilik': [
    'You will no longer be the owner',
    'あなたはオーナーではなくなります',
    '더 이상 내가 소유자가 아니게 돼요',
    '你将不再是群主',
  ],
  'Keluarkan dari grup': ['Remove from group', 'グループから外す', '그룹에서 내보내기', '移出群组'],
  'anggota ini': ['this member', 'このメンバー', '이 멤버', '该成员'],
  'Jadikan {nama} pemilik grup?': [
    'Make {nama} the group owner?',
    '{nama}さんをグループのオーナーにしますか？',
    '{nama}님을 그룹 소유자로 지정할까요?',
    '将 {nama} 设为群主？',
  ],
  'Setelah ini hanya {nama} yang bisa mengeluarkan anggota dan memindahkan kepemilikan.': [
    'After this, only {nama} can remove members and transfer ownership.',
    'この後は、{nama}さんだけがメンバーを外したりオーナーを移したりできます。',
    '이후에는 {nama}님만 멤버를 내보내고 소유권을 넘길 수 있어요.',
    '此后只有 {nama} 可以移出成员和转让群主。',
  ],
  'Jadikan pemilik': ['Make owner', 'オーナーにする', '소유자로 지정', '设为群主'],
  'Keluarkan {nama} dari grup?': [
    'Remove {nama} from the group?',
    '{nama}さんをグループから外しますか？',
    '{nama}님을 그룹에서 내보낼까요?',
    '将 {nama} 移出群组？',
  ],
  'Dia tidak bisa lagi membaca atau mengirim pesan di grup ini.': [
    'They won\'t be able to read or send messages in this group anymore.',
    'この人はこのグループでメッセージを読んだり送ったりできなくなります。',
    '이 사람은 더 이상 이 그룹에서 메시지를 읽거나 보낼 수 없어요.',
    '对方将无法再在此群组中阅读或发送消息。',
  ],
  'Keluarkan': ['Remove', '外す', '내보내기', '移出'],
  'Keluar dari grup "{nama}"?': [
    'Leave the group "{nama}"?',
    'グループ「{nama}」から退出しますか？',
    '"{nama}" 그룹에서 나갈까요?',
    '退出群组“{nama}”？',
  ],
  'Kamu tidak akan menerima pesan baru dari grup ini. Kepemilikan grup pindah ke anggota lain.': [
    'You won\'t receive new messages from this group. Group ownership will pass to another member.',
    'このグループからの新しいメッセージは届かなくなります。オーナー権限は他のメンバーに移ります。',
    '이 그룹의 새 메시지를 더 이상 받지 않아요. 그룹 소유권은 다른 멤버에게 넘어가요.',
    '你将不再收到此群组的新消息，群主身份将转给其他成员。',
  ],
  'Kamu tidak akan menerima pesan baru dari grup ini.': [
    'You won\'t receive new messages from this group.',
    'このグループからの新しいメッセージは届かなくなります。',
    '이 그룹의 새 메시지를 더 이상 받지 않아요.',
    '你将不再收到此群组的新消息。',
  ],
  'Ketuk untuk menambah deskripsi': ['Tap to add a description', 'タップして説明を追加', '눌러서 설명 추가', '点按添加简介'],
  '{jumlah} anggota': ['{jumlah} members', 'メンバー {jumlah}人', '멤버 {jumlah}명', '{jumlah} 名成员'],
  'Pemilik': ['Owner', 'オーナー', '소유자', '群主'],
  'Kamu pemilik grup ini. Ketuk anggota untuk mengeluarkannya atau menjadikannya pemilik.': [
    'You own this group. Tap a member to remove them or make them the owner.',
    'あなたはこのグループのオーナーです。メンバーをタップすると、外したりオーナーにしたりできます。',
    '내가 이 그룹의 소유자예요. 멤버를 눌러 내보내거나 소유자로 지정할 수 있어요.',
    '你是此群组的群主。点按成员可将其移出或设为群主。',
  ],
  'Keluar dari grup': ['Leave group', 'グループを退出', '그룹 나가기', '退出群组'],

  // Profil orang lain
  'Kirim pesan': ['Send message', 'メッセージを送る', '메시지 보내기', '发消息'],
  'Nama lengkap': ['Full name', 'フルネーム', '이름', '全名'],
  'Username': ['Username', 'ユーザー名', '사용자 이름', '用户名'],
  'Kegiatan': ['Activity', '活動', '활동', '身份'],
  'Pelajar': ['Student', '生徒', '학생', '学生'],
  'Mahasiswa': ['University student', '大学生', '대학생', '大学生'],
  'Pekerja / kantoran': ['Worker / office', '社会人 / 会社員', '직장인', '上班族'],
  'Lainnya': ['Other', 'その他', '기타', '其他'],
  'Sekolah': ['School', '学校', '학교', '学校'],
  'Kampus': ['Campus', '大学', '대학교', '大学'],
  'Perusahaan / instansi': ['Company / organization', '会社 / 団体', '회사 / 기관', '公司 / 机构'],
  'Tempat / komunitas': ['Place / community', '場所 / コミュニティ', '장소 / 커뮤니티', '地点 / 社群'],
  'Kelas': ['Class', 'クラス', '반', '班级'],
  'Jurusan': ['Major', '学科', '전공', '专业'],
  'Jabatan / pekerjaan': ['Position / job', '役職 / 仕事', '직책 / 직업', '职位 / 工作'],
  'Keterangan': ['Details', '詳細', '설명', '说明'],
  'Sekolah / kampus': ['School / campus', '学校 / 大学', '학교 / 대학교', '学校 / 大学'],
  'Kelas / jurusan': ['Class / major', 'クラス / 学科', '반 / 전공', '班级 / 专业'],

  // Pesan berbintang
  'Belum ada pesan berbintang': ['No starred messages yet', 'スター付きメッセージはまだありません', '아직 별표 메시지가 없어요', '还没有星标消息'],
  'Tekan lama sebuah pesan di chat, lalu pilih Beri bintang agar mudah dicari lagi.': [
    'Long-press a message in a chat, then choose Star so it\'s easy to find again.',
    'チャットでメッセージを長押しして「スターを付ける」を選ぶと、あとで見つけやすくなります。',
    '채팅에서 메시지를 길게 누른 뒤 별표를 선택하면 나중에 쉽게 찾을 수 있어요.',
    '在聊天中长按消息，然后选择“加星标”，以后就能轻松找到。',
  ],

  // Layanan
  'Kunci grup belum tersedia di HP ini.': [
    'The group key isn\'t available on this phone yet.',
    'このスマホではまだグループの鍵を利用できません。',
    '이 폰에는 아직 그룹 키가 없어요.',
    '此手机上还没有群组密钥。',
  ],
  'Hanya pemilik grup yang bisa mengeluarkan anggota.': [
    'Only the group owner can remove members.',
    'メンバーを外せるのはグループのオーナーだけです。',
    '그룹 소유자만 멤버를 내보낼 수 있어요.',
    '只有群主可以移出成员。',
  ],
  'Hanya pemilik grup yang bisa memindahkan kepemilikan.': [
    'Only the group owner can transfer ownership.',
    'オーナー権限を移せるのはグループのオーナーだけです。',
    '그룹 소유자만 소유권을 넘길 수 있어요.',
    '只有群主可以转让群主身份。',
  ],
  'Seseorang': ['Someone', '誰か', '누군가', '有人'],
  'Pesan baru': ['New message', '新しいメッセージ', '새 메시지', '新消息'],
  'Permintaan pesan dari {nama}': [
    'Message request from {nama}',
    '{nama}さんからのメッセージリクエスト',
    '{nama}님의 메시지 요청',
    '来自 {nama} 的消息请求',
  ],
  'Maksimal {jumlah} chat yang bisa disematkan.': [
    'You can pin up to {jumlah} chats.',
    '固定できるチャットは最大{jumlah}件です。',
    '채팅은 최대 {jumlah}개까지 고정할 수 있어요.',
    '最多只能置顶 {jumlah} 个聊天。',
  ],
  'Username ini sudah dipakai orang lain. Coba yang lain.': [
    'This username is already taken. Try another one.',
    'このユーザー名はすでに使われています。別のものを試してください。',
    '이 사용자 이름은 이미 사용 중이에요. 다른 이름을 써 보세요.',
    '该用户名已被他人使用，请换一个试试。',
  ],
  'Izin Google tidak diberikan': [
    'Google permission was not granted',
    'Google の許可が得られませんでした',
    'Google 권한이 허용되지 않았어요',
    '未获得 Google 授权',
  ],
};
