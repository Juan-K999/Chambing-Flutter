import 'package:chambing_flutter/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('la app arranca en el menú principal sin errores', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ChambingApp());
    await tester.pump();
    expect(find.text('Chambing'), findsOneWidget);
    expect(find.text('Registrar empresa'), findsOneWidget);
    expect(find.text('Registrar usuario'), findsOneWidget);
  });
}
