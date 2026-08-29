// Smoke test: the app boots and shows the Mimo bootstrap screen.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mimo/core/theme/theme_controller.dart';
import 'package:mimo/main.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ThemeController.initialize();
  });

  testWidgets('MimoApp boots and shows the bootstrap screen', (tester) async {
    await tester.pumpWidget(const MimoApp(supabaseConfigured: false));
    await tester.pumpAndSettle();

    expect(find.text('Mimo'), findsOneWidget);
    expect(
      find.text('Copie .env.example para .env com suas chaves do Supabase.'),
      findsOneWidget,
    );
  });
}
