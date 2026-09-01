import 'package:praktikum_3/praktikum_3.dart' as praktikum_3;
import 'dart:io';

void main(List<String> arguments) {
  int a = 10;
  int b = 20;
  print(a == b);
  print(identical(a, b));

  String nama1 = 'Afrizal';
  String nama2 = 'afrizal';
  print(nama1 == nama2);
  print(identical(nama1, nama2));
}
