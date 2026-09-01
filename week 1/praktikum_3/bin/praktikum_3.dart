import 'package:praktikum_3/praktikum_3.dart' as praktikum_3;
import 'dart:io';

void main(List<String> arguments) {
  // print('Hello world: ${praktikum_3.calculate()}!');
  // String? name;
  // name = 'Afrizal';
  // print('Nama saya adalah ${name ?? 'Nama tidak diketahui'}');
  print('Masukkan nama Anda: ');
  String? name = stdin.readLineSync();
  print(
    'Nama saya adalah ${name == null || name.isEmpty ? 'Nama tidak diketahui' : name}',
  );
}
