import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:planificator/repositories/planning_details_repository.dart';
import '../config/mocks.dart';

void main() {
  late PlanningDetailsRepository repository;
  late MockDatabaseService mockDatabase;

  setUp(() {
    mockDatabase = MockDatabaseService();
    repository = PlanningDetailsRepository(databaseService: mockDatabase);
  });

  group('PlanningDetailsRepository - Tri Intelligent', () {
    test('Tri doit placer les Effectués avant les À venir et respecter les ordres chronologiques', () async {
      final now = DateTime.now();
      
      final rawData = [
        {
          'traitement': 'Futur Loin', 
          'etat': 'À venir', 
          'date_planification': now.add(const Duration(days: 30)).toIso8601String()
        },
        {
          'traitement': 'Passé Récent', 
          'etat': 'Effectué', 
          'date_planification': now.subtract(const Duration(days: 1)).toIso8601String()
        },
        {
          'traitement': 'Futur Proche', 
          'etat': 'À venir', 
          'date_planification': now.add(const Duration(days: 2)).toIso8601String()
        },
        {
          'traitement': 'Passé Vieux', 
          'etat': 'Effectué', 
          'date_planification': now.subtract(const Duration(days: 10)).toIso8601String()
        },
      ];

      when(mockDatabase.query(any, any, any))
          .thenAnswer((_) async => rawData);

      await repository.loadAllTreatmentsComplete(useCache: false);
      final sorted = repository.allTreatmentsComplete;

      expect(sorted.length, 4);
      expect(sorted[0]['traitement'], contains('Passé Récent'));
      expect(sorted[1]['traitement'], contains('Passé Vieux'));
      expect(sorted[2]['traitement'], contains('Futur Proche'));
      expect(sorted[3]['traitement'], contains('Futur Loin'));
    });
  });

  group('PlanningDetailsRepository - Robustesse', () {
    test('createPlanningDetails doit retourner l\'existant si la date est déjà prise', () async {
      final date = DateTime(2024, 5, 20);
      
      when(mockDatabase.query(any, any))
          .thenAnswer((_) async => [{'planning_detail_id': 99}]);

      final result = await repository.createPlanningDetails(1, date);

      expect(result?.planningDetailId, 99);
      verifyNever(mockDatabase.insert(any, any));
    });
  });
}
