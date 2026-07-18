import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import '../repositories/index.dart';
import '../services/index.dart';

class AppProviders {
  static List<SingleChildWidget> get providers => [
    // Provider du thème (doit être en premier pour être disponible partout)
    ChangeNotifierProvider(create: (_) => ThemeProvider()..initialize()),

    // Repositories
    ChangeNotifierProvider(create: (_) => AuthRepository()),
    ChangeNotifierProvider(create: (_) => ClientRepository()),
    ChangeNotifierProvider(create: (_) => FactureRepository()),
    ChangeNotifierProvider(create: (_) => ContratRepository()),
    ChangeNotifierProvider(create: (_) => PlanningRepository()),
    ChangeNotifierProvider(create: (_) => PlanningDetailsRepository()),
    ChangeNotifierProvider(create: (_) => HistoriqueRepository()),
    ChangeNotifierProvider(create: (_) => TypeTraitementRepository()),
    ChangeNotifierProvider(create: (_) => RemarqueRepository()),
    ChangeNotifierProvider(create: (_) => SignalementRepository()),
    ChangeNotifierProvider(create: (_) => NotificationRepository()),
  ];
}
