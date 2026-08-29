// Smoke test: the app boots and shows the Mimo bootstrap screen.
import 'package:flutter_test/flutter_test.dart';

import 'package:mimo/main.dart';

void main() {
  testWidgets('MimoApp boots and shows the bootstrap screen', (tester) async {
    await tester.pumpWidget(const MimoApp(supabaseConfigured: false));

    expect(find.text('Mimo'), findsOneWidget);
    expect(
      find.text('Copie .env.example para .env com suas chaves do Supabase.'),
      findsOneWidget,
    );
  });
}
