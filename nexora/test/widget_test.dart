import 'package:flutter_test/flutter_test.dart';
import 'package:nexora/core/di/injection.dart';
import 'package:nexora/core/local/local_storege/i_local_storege.dart';
import 'package:nexora/main.dart';

class FakeLocalSecureStorage implements ILocalSecureStorege {
  final _values = <String, dynamic>{};

  @override
  Future<void> clean() async => _values.clear();

  @override
  Future<bool> contains(String key) async => _values.containsKey(key);

  @override
  Future<V?> read<V>(String key) async => _values[key] as V?;

  @override
  Future<void> remove(String key) async => _values.remove(key);

  @override
  Future<void> write<V>(String key, V value) async => _values[key] = value;
}

void main() {
  setUpAll(() async {
    await initDependencies(secureStorage: FakeLocalSecureStorage());
  });

  testWidgets('App renders login page by default', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Nexora Assiduidade'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });
}
