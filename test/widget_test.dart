import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  test('Prueba automatizada de Red TESO', () {
    // Verifica que el entorno de pruebas de Flutter esté disponible.
    expect(WidgetsFlutterBinding.ensureInitialized(), isNotNull);
  });
}
