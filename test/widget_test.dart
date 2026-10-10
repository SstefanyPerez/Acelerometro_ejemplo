import 'package:flutter_test/flutter_test.dart';

import 'package:acelerometro_ejemplo/main.dart';

void main() {
  testWidgets('El menú muestra los botones de todas las demos', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Acelerómetro y Giroscopio'), findsOneWidget);
    expect(find.text('Permisos'), findsOneWidget);
    expect(find.text('Bolita (valores X, Y, Z)'), findsOneWidget);
    expect(find.text('Muñequito (agítame)'), findsOneWidget);
    expect(find.text('Giroscopio (gira el celular)'), findsOneWidget);
    expect(find.text('Detector de caídas'), findsOneWidget);
  });
}
