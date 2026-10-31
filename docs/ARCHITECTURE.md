# Architecture technique

Planificator est une application Flutter desktop organisée en couches :

- `screens/` et `widgets/` : interface ;
- `repositories/` : règles métier et accès aux données ;
- `services/` : MySQL, cache, logs, notifications, sauvegardes et migrations ;
- `models/` : objets métier ;
- `core/` : initialisation, thème et requêtes SQL ;
- `scripts/` : schéma, maintenance et opérations.

Les écritures multi-tables doivent passer par les transactions de `DatabaseService`.
Les secrets ne doivent jamais être ajoutés au dépôt ni écrits dans les logs.
