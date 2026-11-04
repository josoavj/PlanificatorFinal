# Architecture technique

L'architecture utilisée dans ce projet est une architecture MVVM + Featuresm-first :

- `app/` : démarrage, routes, providers et thème de l'application ;
- `core/` : infrastructure technique (MySQL, requêtes SQL, cache, logs, sécurité, plateforme) ;
- `shared/` : composants d'interface réutilisables par plusieurs fonctionnalités ;
- `features/` : une fonctionnalité métier par dossier (models, repositories, domain, providers, screens) ;
  - `models/` : objets métier ;
  - `repositories/` : accès aux données ;
  - `domain/` : règles métier pures (planning, facturation) ;
  - `screens/` : pages et widgets de la fonctionnalité ;
- `scripts/` : schéma SQL, migrations, maintenance et opérations ;
- `test/` : tests unitaires et d'intégration, miroir de `lib/`.

Les écritures multi-tables doivent passer par les transactions de `DatabaseService`.
Les secrets ne doivent jamais être ajoutés au dépôt ni écrits dans les logs.

## Structure des features

### `features/` : une fonctionnalité métier par dossier

```
features/
├─ auth/            connexion, inscription, récupération de compte, session
│  ├─ models/         User
│  ├─ repositories/   authentification, rôles, mots de passe hachés
│  └─ screens/        login, register, recover_account, auth_page_shell
│
├─ home/            tableau de bord et accueil
│  └─ screens/        home_screen, widgets (stat_card, dashboard_tab, liste des traitements)
│
├─ clients/         gestion des clients (particulier, organisation, société)
│  ├─ models/         Client
│  ├─ repositories/   CRUD clients, recherche, filtres
│  └─ screens/        liste, détail, widgets (carte, édition, planning du client)
│
├─ contrats/        contrats et traitements associés
│  ├─ models/         Contrat, Traitement
│  ├─ repositories/   création, modification, résiliation, durée
│  └─ screens/        liste, création, widgets (carte, détails, vue planning, vue factures)
│
├─ planning/        planning des interventions
│  ├─ domain/         règles pures : génération des dates, jours fériés, répartition 1x/2x/3x
│  ├─ models/         PlanningDetails, Remarque, Signalement
│  ├─ repositories/   persistance des passages, remarques et signalements
│  ├─ providers/      état du calendrier et de la période affichée
│  └─ screens/        planning, détail, widgets (calendrier, carte, dialogues)
│
├─ factures/        facturation
│  ├─ domain/         règles pures : regroupement par date de passage, cascade de prix
│  ├─ models/         Facture, HistoriquePrix
│  ├─ repositories/   accès aux données et transactions
│  ├─ providers/      état (ChangeNotifier) : filtres, chargement différé
│  └─ screens/        liste, détail, widgets (groupe de factures, édition du prix)
│
├─ historique/      journal de bord 360° par client
│  ├─ models/         HistoriqueEvent
│  ├─ repositories/   événements, interventions, remarques liées
│  └─ screens/        liste des clients, détail, widgets (catégories, interventions)
│
├─ catalogue/       catalogue dynamique des types de traitement
│  ├─ models/         TypeTraitement, TypeTraitementCategory
│  ├─ repositories/   catégories, activation et masquage des traitements
│  └─ screens/        gestion du catalogue (administrateur)
│
├─ users/           administration des comptes
│  └─ screens/        gestion des utilisateurs et des rôles (administrateur)
│
├─ profile/         profil de l'utilisateur connecté
│  └─ screens/        profil, widgets (modification, changement de mot de passe)
│
├─ notifications/   rappels d'interventions
│  ├─ repositories/   préférences et historique des notifications
│  ├─ services/       planification et envoi des notifications
│  └─ screens/        réglage de l'heure de notification
│
├─ backup/          sauvegarde et restauration
│  └─ services/       export et import de la base
│
├─ export/          exports de données
│  └─ screens/        export Excel (factures, planning)
│
├─ settings/        réglages de l'application
│  └─ screens/        réglages, configuration de la base (premier lancement et dialogue),
│                     visualiseur de logs
│
├─ legal/           mentions légales
│  └─ screens/        politique de confidentialité, conditions d'utilisation
│
└─ about/           informations sur l'application
   └─ screens/        version, éditeur, fonctionnalités
```

### Rôle de chaque sous-dossier

```
<feature>/
├─ domain/         règles métier pures en Dart (testables sans base ni Flutter)
├─ models/         objets métier : champs, fromMap / toMap, copyWith
├─ repositories/   accès aux données de la feature (SQL, transactions, cache)
├─ providers/      état de la feature (ChangeNotifier) entre écran et repository
├─ services/       capacités techniques propres à la feature (notifications, sauvegarde)
└─ screens/        pages, dialogues et widgets spécifiques à la feature
   └─ widgets/       composants utilisés par un seul écran
```

### Règles

- Une feature **n'importe pas** une autre feature : ce qui est partagé monte dans `core/` ou `shared/`.
- `domain/` n'importe ni Flutter, ni MySQL, ni Provider.
- Un écran ne contient ni SQL ni calcul métier.
- Un dossier n'existe que s'il est utile : `users/` n'a pas besoin de `models/`, `legal/` n'a besoin que de `screens/`.