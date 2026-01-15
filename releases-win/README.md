# Planificator v2.1.1

## 📋 Informations Release

**Version:** 2.1.1  
**Date de Release:** Janvier 2026  
**Plateforme:** Windows 
**Framework:** Flutter 3.x + Dart

---

## ✨ Fonctionnalités Principales

### 📊 Export de Factures
- **Export Excel complet** des factures avec tous les détails
- **Informations enrichies** :
  - Nom, prénom, catégorie et adresse du client
  - Numéro de téléphone du client
  - Référence du contrat associé
  - Type de traitement effectué
- **Formatage professionnel** :
  - Dates au format `dd/mm/yy`
  - Montants formatés avec séparateurs français (90 000 Ar, 120 000 Ar, etc.)
  - En-têtes gras et centrés
- **Filtrage par mois** ou export annuel
- **Coloration intelligente** :
  - Lignes vertes pour les factures payées
  - Lignes rouges pour les factures non payées ou à venir

### 📈 Export de Traitements
- **Export Excel** de tous les traitements avec statistiques
- **Informations détaillées** :
  - Date et statut de planification
  - Type de traitement
  - Montant associé
- **Coloration par statut** :
  - Vert pour les traitements effectués
  - Rouge pour les traitements à venir
- **Totaux automatiques** groupés par type de traitement
- **Filtrage par mois**

### 💳 Détails de Paiement Enrichis
- **Modes de paiement** : Chèque, Virement, Mobile Money, Espèce
- **Informations détaillées** selon le mode :
  - Pour les chèques : numéro, établissement, date
  - Pour les virements/Mobile Money : date de transaction
  - Pour l'espèce : date de paiement
- **État du paiement** : Payé, Non payé, À venir

### 📁 Gestion des Fichiers
- **Dossiers automatiques** créés sur le Bureau (ou Documents en fallback)
  - Dossier "Factures" pour les exports de factures
  - Dossier "Traitements" pour les exports de traitements
- **Chemins complets affichés** à l'utilisateur après chaque export
- **Nommage intelligent** des fichiers avec client et mois

### 🎨 Mise en Forme Excel
- **En-têtes stylisés** : bold, 14pt, couleur d'arrière-plan
- **Bordures** sur toutes les cellules pour meilleure lisibilité
- **Colonnes redimensionnées** automatiquement pour le contenu
- **Totaux groupés** par type de traitement avec subtotaux
- **Montants totaux** : Total facturé, Total payé, Total restant

### 🔍 Filtrage et Sélection
- **Sélection du client** avant export
- **Sélection du mois** (ou tous les mois pour annuel)
- **Prévisualisation** du mois sélectionné

---

## 🐛 Corrections et Améliorations

### v2.1.1
- ✅ Export Excel sans erreurs de style
- ✅ Affichage correct des chemins d'export
- ✅ Enrichissement automatique des données client
- ✅ Formatage des devises et dates français
- ✅ Coloration intelligente des lignes
- ✅ Détails de paiement complets
- ✅ Correction du filtrage par mois
- ✅ Gestion robuste des types (int, double, string)
- ✅ Cache de styles pour éviter les doublons

---

## 📝 Notes Techniques

### Architecture
- **State Management** : Provider pattern
- **Génération Excel** : Syncfusion xlsio
- **Localisation** : Dates et nombres au format français
- **Gestion des fichiers** : path_provider pour chemins systèmes

### Patterns Clés
1. **Style Creation Pattern** : Les styles sont créés avant toute assignation de propriétés
2. **Type Safety** : Conversion explicite int/double/string pour les montants
3. **DateTime Handling** : Passage des DateTime objects à l'Excel, formatage appliqué en dernier
4. **Style Caching** : Réutilisation des styles pour performance

---

## 🚀 Utilisation

### Export de Factures
1. Allez dans l'écran "Export"
2. Sélectionnez un client
3. Sélectionnez un mois ou "Tous" pour l'annuel
4. Appuyez sur "Exporter Factures"
5. Un fichier Excel est généré sur le Bureau (dossier "Factures")

### Export de Traitements
1. Allez dans l'écran "Export"
2. Sélectionnez un mois
3. Appuyez sur "Exporter Traitements"
4. Un fichier Excel est généré sur le Bureau (dossier "Traitements")

---

## ⚙️ Configu

- **Navigateurs Chrome/Edge supportés** pour la version web
- **Android 5.0+** minimum
- **iOS 11.0+** minimum

---

## 📞 Support

Pour toute question ou rapport de bug, veuillez contacter l'équipe de développement.

