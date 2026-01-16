import 'package:flutter_modular_lc/src/flutter_modular_module.dart';
import 'package:flutter_modular_lc/src/presenter/modular_base.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    ModularInjectors.initialize();
  });

  tearDown(() {
    ModularInjectors.dispose();
  });

  test('resolver injection (ModularBase)', () {
    expect(injector.get<IModularBase>(), isA<ModularBase>());
  });
}
