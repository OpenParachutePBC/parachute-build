import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:parachute_build/main.dart';

void main() {
  testWidgets('Build app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: ParachuteBuildApp()));
    expect(find.text('Build'), findsOneWidget);
  });
}
