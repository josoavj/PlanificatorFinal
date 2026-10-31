# Exploitation et déploiement

## Initialisation

1. Installer MySQL 8 ou MariaDB compatible.
2. Exécuter `scripts/Planificator.sql`.
3. Configurer la connexion dans l’écran de démarrage.
4. L’application applique ensuite les migrations versionnées au démarrage.

## Schéma et maintenance

Le fichier `scripts/Planificator.sql` est l'unique source SQL du projet. Il crée le
schéma complet, les contraintes, les triggers, les index et les statistiques.
Le script recrée la base `Planificator` ; il ne doit donc être exécuté que lors
de l'initialisation ou d'un redéploiement volontaire.

```bash
mysql -u planificator -p < scripts/Planificator.sql
```

Ce déploiement supprime et recrée la base. Effectuer une sauvegarde avant toute
exécution en environnement existant.

## Sauvegarde

La sauvegarde applicative est disponible via `BackupService`. Pour une sauvegarde
administrateur complète, utiliser :

```bash
MYSQL_USER=planificator MYSQL_DATABASE=Planificator \
  MYSQL_PASSWORD='...' ./scripts/backup_database.sh
```

Les fichiers de sauvegarde doivent être chiffrés et stockés hors du répertoire public.

## CI/CD

Le workflow `ci.yaml` exécute le formatage, l’analyse, les tests et un build Linux.
Le workflow `pages.yaml` publie le contenu de `docs/` sur GitHub Pages.

Les workflows de release publient :

- Windows : `planificator-windows-x64-vVERSION.zip` et `Planificator_Setup_vVERSION.exe` ;
- Linux : `planificator-linux-x64.tar.gz` et `planificator_VERSION_amd64.deb`.

L'archive Linux peut être installée automatiquement avec :

```bash
curl -fsSL https://raw.githubusercontent.com/josoavj/PlanificatorFinal/master/scripts/install-linux.sh \
  -o /tmp/install-planificator.sh
bash /tmp/install-planificator.sh
```

Le schéma distribué dans tous les livrables est uniquement
`Database/Planificator.sql`.
