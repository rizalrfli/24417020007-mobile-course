import 'package:flutter_test/flutter_test.dart';
import 'package:week_3/detail_lagu.dart';
import 'package:week_3/main.dart';

void main() {
  testWidgets('Detail lagu dapat dibuka dan kembali ke halaman utama', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp());
    await tester.tap(find.text('Detail lagu'));
    await tester.pumpAndSettle();

    expect(find.byType(DetailLagu), findsOneWidget);
    expect(find.text('Penyanyi: Hindia'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Kembali'));
    await tester.pumpAndSettle();

    expect(find.byType(DetailLagu), findsNothing);
    expect(find.text('Cari Judul Lagu'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
