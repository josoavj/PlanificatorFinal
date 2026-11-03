import 'package:planificator/app/theme/theme_provider.dart';
import 'package:planificator/features/auth/repositories/auth_repository.dart';
import 'package:planificator/features/catalogue/repositories/type_traitement_repository.dart';
import 'package:planificator/features/clients/repositories/client_repository.dart';
import 'package:planificator/features/contrats/repositories/contrat_repository.dart';
import 'package:planificator/features/factures/repositories/facture_repository.dart';
import 'package:planificator/features/historique/repositories/historique_repository.dart';
import 'package:planificator/features/notifications/repositories/notification_repository.dart';
import 'package:planificator/features/planning/repositories/planning_details_repository.dart';
import 'package:planificator/features/planning/repositories/planning_repository.dart';
import 'package:planificator/features/planning/repositories/remarque_repository.dart';
import 'package:planificator/features/planning/repositories/signalement_repository.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

class AppProviders {
  static List<SingleChildWidget> get providers => [
    // Provider du thème (doit être en premier pour être disponible partout)
    ChangeNotifierProvider(create: (_) => ThemeProvider()..initialize()),

    // Repositories
    ChangeNotifierProvider(create: (_) => AuthRepository()),
    ChangeNotifierProxyProvider<AuthRepository, ClientRepository>(
      create: (_) => ClientRepository(),
      update: (_, auth, repository) => repository!..authRepository = auth,
    ),
    ChangeNotifierProxyProvider<AuthRepository, FactureRepository>(
      create: (_) => FactureRepository(),
      update: (_, auth, repository) => repository!..authRepository = auth,
    ),
    ChangeNotifierProxyProvider<AuthRepository, ContratRepository>(
      create: (_) => ContratRepository(),
      update: (_, auth, repository) => repository!..authRepository = auth,
    ),
    ChangeNotifierProvider(create: (_) => PlanningRepository()),
    ChangeNotifierProvider(create: (_) => PlanningDetailsRepository()),
    ChangeNotifierProvider(create: (_) => HistoriqueRepository()),
    ChangeNotifierProvider(create: (_) => TypeTraitementRepository()),
    ChangeNotifierProvider(create: (_) => RemarqueRepository()),
    ChangeNotifierProvider(create: (_) => SignalementRepository()),
    ChangeNotifierProvider(create: (_) => NotificationRepository()),
  ];
}
