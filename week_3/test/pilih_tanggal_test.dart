import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week_3/pilih_tanggal.dart';

void main() {
  testWidgets('Tanggal tersimpan, dibuka kembali, dan tetap saat batal', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PilihTanggal())),
    );

    expect(find.text('Belum ada tanggal dipilih'), findsOneWidget);
    await tester.tap(find.text('Pilih tanggal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(find.text('Belum ada tanggal dipilih'), findsOneWidget);

    await tester.tap(find.text('Pilih tanggal'));
    await tester.pumpAndSettle();
    final awal = tester.widget<DatePickerDialog>(find.byType(DatePickerDialog));
    final pilihan = DateTime(awal.initialDate!.year, awal.initialDate!.month, 15);
    await tester.tap(find.text('15'));
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    final hasil = 'Tanggal dipilih: 15/${pilihan.month}/${pilihan.year}';
    expect(find.text(hasil), findsOneWidget);
    await tester.tap(find.text('Ubah tanggal'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<DatePickerDialog>(find.byType(DatePickerDialog)).initialDate,
      pilihan,
    );
    await tester.tap(find.text('16'));
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(find.text(hasil), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
