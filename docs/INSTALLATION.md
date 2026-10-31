# Installer Planificator

## Pré-requis

- Flutter/Dart correspondant à `pubspec.yaml` pour compiler ;
- MySQL 8 ou MariaDB compatible ;
- Windows, Linux ou macOS pour l'application desktop.

## Base de données

```bash
mysql -u root -p < scripts/Planificator.sql
```

Le premier démarrage et chaque reconfiguration administrateur vérifient le schéma.
Pour initialiser une base :

```bash
mysql -u planificator -p < scripts/Planificator.sql
```

`Planificator.sql` est l'unique script SQL distribué. Il supprime et recrée la
base `Planificator` ; sauvegardez toute base existante avant son exécution.

## Développement

```bash
flutter pub get
flutter run -d windows   # ou linux / macos
```

## Production

Télécharger l'archive publiée dans GitHub Releases. Configurer un compte MySQL dédié,
limiter son réseau, activer TLS et effectuer une sauvegarde avant toute migration.

Sous Linux, l'archive peut être installée avec `scripts/install-linux.sh`. Le paquet
`.deb` est également disponible dans chaque release. Sous Windows, utiliser
`Planificator_Setup_vVERSION.exe` pour installer l'application, le runtime Visual C++
et le schéma SQL.
