import 'package:material_ui/material_ui.dart';
import 'package:planificator/features/auth/repositories/auth_repository.dart';
import 'package:planificator/features/auth/screens/login_screen.dart';
import 'package:planificator/features/auth/screens/register_screen.dart';
import 'package:planificator/features/home/screens/home_screen.dart';
import 'package:provider/provider.dart';

import '../core/logging/logging_service.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late Future<bool> _bootstrapFuture;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = context.read<AuthRepository>().hasNoUsers();
    log.info(
      'AuthGate initialized - data loading deferred to screens',
      source: 'main',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Selector<AuthRepository, bool>(
      selector: (_, auth) =>
          auth.isAuthenticated || auth.lastGeneratedRecoveryCode != null,
      builder: (context, _, _) {
        final auth = context.read<AuthRepository>();
        if (auth.isAuthenticated) {
          return const HomeScreen();
        }
        if (auth.lastGeneratedRecoveryCode != null) return const LoginScreen();
        return FutureBuilder<bool>(
          future: _bootstrapFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return snapshot.data == true
                ? const RegisterScreen(isBootstrap: true)
                : const LoginScreen();
          },
        );
      },
    );
  }
}
