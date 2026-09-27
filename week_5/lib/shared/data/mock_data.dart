import '../models/music.dart';

const _artistSenja = Artist(id: 'senja', name: 'Ruang Senja', isDemo: true);
const _artistUtara = Artist(id: 'utara', name: 'Nada Utara', isDemo: true);
const _artistBiru = Artist(id: 'biru', name: 'Studio Biru', isDemo: true);

const _artistHindia = Artist(
  id: 'hindia',
  name: 'Hindia',
  imageUrl: 'assets/cover/everything-u-are.png',
);
const _artistFeast = Artist(
  id: 'feast',
  name: '.Feast',
  imageUrl: 'assets/cover/nina.png',
);
const _artistPayungTeduh = Artist(
  id: 'payung-teduh',
  name: 'Payung Teduh',
  imageUrl: 'assets/cover/payung-teduh.png',
);
const _artistOliviaRodrigo = Artist(
  id: 'olivia-rodrigo',
  name: 'Olivia Rodrigo',
  imageUrl: 'assets/cover/honeybee.png',
);

const mockArtists = [
  _artistHindia,
  _artistFeast,
  _artistPayungTeduh,
  _artistOliviaRodrigo,
];

const allMockArtists = [
  _artistHindia,
  _artistFeast,
  _artistPayungTeduh,
  _artistOliviaRodrigo,
  _artistSenja,
  _artistUtara,
  _artistBiru,
];

const _nightAlbum = Album(
  id: 'malam',
  title: 'Catatan Malam',
  releaseYear: 2026,
);
const _journeyAlbum = Album(
  id: 'jalan',
  title: 'Jalan Pulang',
  releaseYear: 2025,
);
const _quietAlbum = Album(id: 'jeda', title: 'Sebuah Jeda', releaseYear: 2026);
const _feastAlbumMem = Album(
  id: 'membangun-menghancurkan',
  title: 'Membangun & Menghancurkan',
  coverUrl: 'assets/cover/nina.png',
  releaseYear: 2024,
);
const _feastAlbumPer = Album(
  id: 'beberapa-orang-memaafkan',
  title: 'Beberapa Orang Memaafkan',
  coverUrl: 'assets/cover/peradaban.png',
  releaseYear: 2018,
);
const _payungTeduhAlbum = Album(
  id: 'ruang-tunggu',
  title: 'Ruang Tunggu',
  coverUrl: 'assets/cover/payung-teduh.png',
  releaseYear: 2017,
);
const _hindiaAlbum = Album(
  id: 'menari-dengan-bayangan',
  title: 'Menari dengan Bayangan',
  coverUrl: 'assets/cover/everything-u-are.png',
  releaseYear: 2019,
);
const _oliviaAlbumGuts = Album(
  id: 'guts-spilled',
  title: 'GUTS (spilled)',
  coverUrl: 'assets/cover/honeybee.png',
  releaseYear: 2024,
);

const mockSongs = <Song>[
  Song(
    id: 'nina',
    title: 'Nina',
    artist: _artistFeast,
    album: _feastAlbumMem,
    coverUrl: 'assets/cover/nina.png',
    durationSeconds: 287,
    genre: 'Indie Rock',
    releaseYear: 2024,
  ),
  Song(
    id: 'peradaban',
    title: 'Peradaban',
    artist: _artistFeast,
    album: _feastAlbumPer,
    coverUrl: 'assets/cover/peradaban.png',
    durationSeconds: 340,
    genre: 'Rock',
    releaseYear: 2018,
  ),
  Song(
    id: 'akad',
    title: 'Akad',
    artist: _artistPayungTeduh,
    album: _payungTeduhAlbum,
    coverUrl: 'assets/cover/payung-teduh.png',
    durationSeconds: 258,
    genre: 'Folk Pop',
    releaseYear: 2017,
  ),
  Song(
    id: 'everything-u-are',
    title: 'Everything U Are',
    artist: _artistHindia,
    album: _hindiaAlbum,
    coverUrl: 'assets/cover/everything-u-are.png',
    durationSeconds: 236,
    genre: 'Indie Pop',
    releaseYear: 2024,
  ),
  Song(
    id: 'honeybee',
    title: 'Honeybee',
    artist: _artistOliviaRodrigo,
    album: _oliviaAlbumGuts,
    coverUrl: 'assets/cover/honeybee.png',
    durationSeconds: 153,
    genre: 'Indie Folk',
    releaseYear: 2024,
  ),
  Song(
    id: 'pelan-pelan',
    title: 'Pelan-Pelan',
    artist: _artistBiru,
    album: _quietAlbum,
    durationSeconds: 242,
    genre: 'Acoustic',
    releaseYear: 2026,
    isDemo: true,
  ),
  Song(
    id: 'ruang-kecil',
    title: 'Ruang Kecil',
    artist: _artistSenja,
    album: _nightAlbum,
    durationSeconds: 215,
    genre: 'Indie pop',
    releaseYear: 2026,
    isDemo: true,
  ),
  Song(
    id: 'arah-pulang',
    title: 'Arah Pulang',
    artist: _artistUtara,
    album: _journeyAlbum,
    durationSeconds: 231,
    genre: 'Alternative',
    releaseYear: 2025,
    isDemo: true,
  ),
  Song(
    id: 'hening',
    title: 'Hening',
    artist: _artistBiru,
    album: _quietAlbum,
    durationSeconds: 176,
    genre: 'Instrumental',
    releaseYear: 2026,
    isDemo: true,
  ),
];

const mockLyrics = <String, String>{
  'nina':
      'Saat dewasa kau \'kan mengerti\n'
      'Berapa harga satu hari\n'
      'Saat dewasa kau \'kan pahami\n'
      'Mengapa kami jarang di rumah\n\n'
      'Pasti ada yang dikorbankan\n'
      'Pasti ada yang dikeluhkan\n'
      'Tapi kuharap kau \'kan paham\n'
      'Semua kulakukan untukmu\n\n'
      'Untuk segala doa yang belum tercapai\n'
      'Biar kurawat sampai kau siap nanti\n'
      'Tumbuhlah kuat, jadi manusia\n'
      'Karna dunia tak selalu ramah\n'
      'Nina...',
  'akad':
      'Betapa bahagianya hatiku saat\n'
      'Kududuk berdua denganmu\n'
      'Berjalan bersamamu\n'
      'Menari-nari namun\n\n'
      'Bila nanti saatnya t\'lah tiba\n'
      'Kuingin kau menjadi istriku\n'
      'Berjalan bersamamu dalam terik dan hujan\n'
      'Berlarian ke sana-kemari dan tertawa\n\n'
      'Namun bila saat berpisah t\'lah tiba\n'
      'Izinkanku menjaga dirimu\n'
      'Berdua menikmati pelukan di ujung waktu\n'
      'Sudikah kau temani diriku?',
  'everything-u-are':
      'Wajahmu kuingat selalu lupakan\n'
      'Hal-hal yang menggangguku\n'
      'Karena hari ini mata kita beradu\n'
      'Kita saling bantu melepas perasaan\n'
      'Tinggi ke angkasa menantang dunia\n'
      'Merayakan muda tuk satu jam saja\n'
      'Kita hampir mati dan kau selamatkan aku\n'
      'Dan ku menyelamatkanmu dan sekarang aku tahu\n'
      'Cerita kita tak jauh berbeda\n'
      'Got beat down by the world sometimes I wanna fold\n'
      'Namun suratmu kan kuceritakan ke anak-anakku nanti\n'
      'Bahwa aku pernah dicintai with everything u are\n'
      'Fully as I am with everything u are',
  'pelan-pelan':
      'Pelan-pelan pagi terbuka\n'
      'Secangkir teh di tepi jendela\n'
      'Hari ini tak perlu berlari\n'
      'Ada waktu untuk diri sendiri\n\n'
      'Taruh dulu semua pertanyaan\n'
      'Di meja kecil dekat tanaman\n'
      'Dengarkan angin dari halaman\n'
      'Kita mulai lagi perlahan',
  'ruang-kecil':
      'Di ruang kecil kita berbagi\n'
      'Cerita panjang selepas pagi\n'
      'Sebuah kursi menghadap taman\n'
      'Menunggu siapa yang ingin tinggal\n\n'
      'Buku terbuka di halaman lama\n'
      'Ada namamu di antara kata\n'
      'Kubaca lagi tanpa suara\n'
      'Sampai senja mengetuk kaca',
  'arah-pulang':
      'Peta terlipat di dalam tas\n'
      'Jalan membentang selepas batas\n'
      'Di setiap tikungan yang kulalui\n'
      'Ada alasan untuk kembali\n\n'
      'Aku mengenal bau tanah ini\n'
      'Dan suara pagar di ujung hari\n'
      'Sejauh apa langkah kubawa\n'
      'Arah pulang tetap sama',
  'honeybee':
      'So I guess that it\'s true\n'
      'Time can heal even the worst of wounds\n'
      'And the clichés I knew\n'
      'Seem so commonplace when I saw you\n'
      'Let\'s just walk in the dark\n'
      'Hop the fence in the park\n'
      'Baby boy, honeybee\n'
      'God, I love the way you look at me\n\n'
      'And it\'s too hard to describe this\n'
      'In a way that feels honest, but even when I\'m quiet\n'
      'I love you, baby, I promise\n'
      'And I hope I never see what your face looks like goin\'\n'
      'A face, I swear, that I could spend my whole life knowin\'\n'
      'Here\'s to hopin\'\n\n'
      'Pick me up, walk me home\n'
      'Man, it feels like God threw me a bone\n'
      'Sticky sweet, tangerine\n'
      'Would you sit and keep me company?\n'
      'In the dark, I\'m not scared\n'
      'I just reach and you\'re right there\n'
      'Shooting stars, racing cars\n'
      'Everything I own just feels like ours\n\n'
      'It\'s too hard to describe this\n'
      'In a way that feels honest, but even when I\'m quiet\n'
      'I love you, baby, I promise\n'
      'And I hope I never see what your face looks like goin\'\n'
      'A face, I swear, that I could spend my whole life knowin\'\n'
      'Here\'s to hopin\'\n\n'
      'I hope I never see what your face looks like goin\'\n'
      'A face, I swear, that I could spend my whole life knowin\'\n'
      'Here\'s to hopin\'\n\n'
      'It\'s too hard to describe this\n'
      'In a way that feels honest, but even when I\'m quiet\n'
      'I promise\n'
      'And I hope I never see what your face looks like goin\'\n'
      'A face, I swear, that I could spend my whole life knowin\'\n'
      'Here\'s to hopin\'',
};
