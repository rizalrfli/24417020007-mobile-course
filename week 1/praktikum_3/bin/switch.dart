import 'package:praktikum_3/praktikum_3.dart' as praktikum_3;
import 'dart:io';

void main(List<String> arguments) {
  String? name = stdin.readLineSync();
  switch (name) {
    case null:
      print('Nama tidak diketahui');
      break;
    case '':
      print('Nama tidak diketahui');
      break;
    default:
      print('Nama saya adalah $name');
  }
}
