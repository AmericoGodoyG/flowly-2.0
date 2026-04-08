import 'package:flutter_test/flutter_test.dart';
import 'package:meu_app/src/app/flowly_app.dart';

void main() {
  testWidgets('Renderiza os campos da tela de login', (WidgetTester tester) async {
    await tester.pumpWidget(const FlowlyApp());

    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('E-mail'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
  });
}
