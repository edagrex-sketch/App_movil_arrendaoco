import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arrendaoco/widgets/stunning_widgets.dart';

void main() {
  testWidgets('StunningButton displays text and icon', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StunningButton(
            text: 'Prueba',
            icon: Icons.check,
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(find.text('Prueba'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('StunningTextField displays label and icon', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StunningTextField(
            controller: TextEditingController(),
            label: 'Campo Prueba',
            icon: Icons.edit,
          ),
        ),
      ),
    );

    expect(find.text('Campo Prueba'), findsOneWidget);
    expect(find.byIcon(Icons.edit), findsOneWidget);
  });
}
