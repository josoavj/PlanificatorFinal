class AppConstants {
  // Database Configuration
  // Configuration stockée dans database_config.dart
  static const String appName = 'planificator';
  static const String appVersion = '2.0.0';
  static const String appBuild = '1';

  // Messages
  static const String msgLoading = 'Chargement...';
  static const String msgError = 'Une erreur est survenue';
  static const String msgSuccess = 'Opération réussie';
  static const String msgConfirmDelete = 'Êtes-vous sûr de vouloir supprimer ?';
  static const String msgNoData = 'Aucune donnée trouvée';
  static const String msgValidationError = 'Veuillez corriger les erreurs';

  // Validation
  static const int minPasswordLength = 6;
  static const int maxNameLength = 100;
  static const int maxEmailLength = 100;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxRetries = 3;

  // Timeouts
  static const Duration shortDuration = Duration(milliseconds: 300);
  static const Duration mediumDuration = Duration(milliseconds: 500);
  static const Duration longDuration = Duration(milliseconds: 800);

  // Routes
  static const String routeLogin = '/login';
  static const String routeRegister = '/register';
  static const String routeHome = '/home';
  static const String routeClients = '/clients';
  static const String routeClient = '/client';
  static const String routeContrats = '/contrats';
  static const String routePlanning = '/planning';
  static const String routeFactures = '/factures';
  static const String routeHistorique = '/historique';
  static const String routeSettings = '/settings';

  // Keys for local storage
  static const String keyAuthToken = 'auth_token';
  static const String keyUser = 'user';
  static const String keyClients = 'clients';
  static const String keyContrats = 'contrats';

  // Date formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';

  // Error Messages
  static const String networkError = 'Erreur de connexion';
  static const String unexpectedError = 'Une erreur inattendue s\'est produite';
  static const String invalidCredentials = 'Email ou mot de passe invalide';

  // Success Messages
  static const String loginSuccess = 'Connexion réussie';
  static const String logoutSuccess = 'Déconnexion réussie';
  static const String operationSuccess = 'Opération réussie';
}
