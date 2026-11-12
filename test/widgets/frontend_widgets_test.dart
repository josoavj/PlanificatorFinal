import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planificator/features/home/widgets/stat_card.dart';
import 'package:planificator/shared/widgets/empty_state_widget.dart';
import 'package:planificator/shared/widgets/error_widget.dart';

void main() {
  group('Frontend UI Widgets Tests', () {
    testWidgets(
      'DashboardStatCard affiche correctement le titre, la valeur et le sous-titre',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: DashboardStatCard(
                title: 'Traitements du mois',
                value: '42',
                icon: Icons.assignment_outlined,
                color: Colors.blue,
                subtitle: '42 interventions prévues',
              ),
            ),
          ),
        );

        expect(find.text('Traitements du mois'), findsOneWidget);
        expect(find.text('42'), findsOneWidget);
        expect(find.text('42 interventions prévues'), findsOneWidget);
        expect(find.byIcon(Icons.assignment_outlined), findsOneWidget);
      },
    );

    testWidgets(
      'EmptyStateWidget affiche le titre, message et déclenche l\'action au clic',
      (WidgetTester tester) async {
        bool actionTriggered = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmptyStateWidget(
                title: 'Aucun client',
                message: 'Aucun résultat trouvé pour votre recherche',
                icon: Icons.person_off_outlined,
                actionLabel: 'Actualiser',
                onAction: () => actionTriggered = true,
              ),
            ),
          ),
        );

        expect(find.text('Aucun client'), findsOneWidget);
        expect(
          find.text('Aucun résultat trouvé pour votre recherche'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.person_off_outlined), findsOneWidget);
        expect(find.text('Actualiser'), findsOneWidget);

        await tester.tap(find.text('Actualiser'));
        await tester.pump();

        expect(actionTriggered, isTrue);
      },
    );

    testWidgets(
      'ErrorDisplayWidget affiche l\'erreur et déclenche le bouton Réessayer',
      (WidgetTester tester) async {
        bool retryTriggered = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ErrorDisplayWidget(
                message: 'Erreur réseau de test',
                onRetry: () => retryTriggered = true,
              ),
            ),
          ),
        );

        expect(find.text('Erreur'), findsOneWidget);
        expect(find.text('Erreur réseau de test'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.text('Réessayer'), findsOneWidget);

        await tester.tap(find.text('Réessayer'));
        await tester.pump();

        expect(retryTriggered, isTrue);
      },
    );
  });
}
