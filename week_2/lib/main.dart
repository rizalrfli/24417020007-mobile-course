import 'package:flutter/material.dart';
import 'mahasiswa.dart';
import 'liriklagu.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final Liriklagu liriklagu = Liriklagu(
    judul: 'Everything u are',
    penyanyi: 'Hindia',
    bait1:
        'Wajahmu ku ingat selalu lupakan\n Hal-hal yang menggangguku\n Karena hari ini mata kita beradu\n Kita saling bantu melepas perasaan\n Tinggi ke angkasa menantang dunia\n Merayakan muda tuk satu jam saja\n Kita hampir mati dan kau selamatkan aku\n Dan ku menyelamatkanmu dan sekarang aku tahu\n Cerita kita tak jauh berbeda\n Got beat down by the world sometimes I wanna fold\n Namun suratmu kan ku ceritakan ke anak-anakku nanti\n Bahwa aku pernah dicintai with everything u are\n Fully as I am with everything u are',
    bait2:
        'Wajahmu yang beragam rupa pastikan\n Ku tak sendirian\n Jalani derita kau bawakan kisahmu\n Aku mendengarkan oh kita bergantian\n Bertukar nestapa menawar trauma\n Datang seadanya terasku terbuka\n Kita hampir mati dan kau sеlamatkan aku\n Dan ku menyelamatkanmu dan sekarang aku tahu\n Cеrita kita tak jauh berbeda\n Got beat down by the world sometimes I wanna fold\n Namun suratmu kan kuceritakan ke anak-anakku nanti\n Bahwa aku pernah dicintai\n Seada-adanya sekurang-kurangnya\n Walau sulit utarakan hatiku dengan indah\n Walau jarang ku bernyanyi dengan cara yang indah\n Tapi tak sekali pun kisahku pernah kau bantah hu\n Cerita kita tak jauh berbeda\n Got beat down by the world sometimes I wanna fold\n Namun suratmu kan ku ceritakan ke anak-anakku nanti\n Bahwa aku pernah dicintai with everything u are\n Fully as I am with everything u are',
  );
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('Afrizal Rafli Kusuma Wardana')),
        body: SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                Text(
                  liriklagu.judul,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  liriklagu.penyanyi,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color.fromARGB(255, 5, 5, 5),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  liriklagu.bait1,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 20),
                Text(
                  liriklagu.bait2,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: BottomAppBar(
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous_rounded),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.play_circle_rounded),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.skip_next_rounded),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
