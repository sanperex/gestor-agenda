import 'package:flutter_test/flutter_test.dart';

import 'package:gestor_agenda/core/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('vacío', () => expect(Validators.email(''), 'Ingresa tu correo'));
    test('sin @', () => expect(Validators.email('ana.com'), isNotNull));
    test('válido', () => expect(Validators.email(' ana@test.com '), isNull));
  });

  group('Validators.password', () {
    test('corta', () => expect(Validators.password('123'), isNotNull));
    test('válida', () => expect(Validators.password('123456'), isNull));
  });

  group('Validators.name', () {
    test('muy corto', () => expect(Validators.name('A'), isNotNull));
    test('válido', () => expect(Validators.name('Ana'), isNull));
  });

  test('confirmPassword', () {
    expect(Validators.confirmPassword('abc123', 'abc124'), 'Las contraseñas no coinciden');
    expect(Validators.confirmPassword('abc123', 'abc123'), isNull);
  });

  test('resetCode', () {
    expect(Validators.resetCode('12345'), isNotNull);
    expect(Validators.resetCode('12a456'), isNotNull);
    expect(Validators.resetCode('123456'), isNull);
  });
}
