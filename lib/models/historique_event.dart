/// Modèle HistoriqueEvent
/// Représente une entrée dans l'historique technique des traitements.
/// Aligné sur la table SQL 'Historique'.
class HistoriqueEvent {
  final int historiqueId;
  final int factureId;
  final int? planningDetailId;
  final int? signalementId;
  final DateTime date;
  final String contenu;
  final String? issue;
  final String action;

  // Données de jointure optionnelles
  final DateTime? datePlanification;

  HistoriqueEvent({
    required this.historiqueId,
    required this.factureId,
    this.planningDetailId,
    this.signalementId,
    required this.date,
    required this.contenu,
    this.issue,
    required this.action,
    this.datePlanification,
  });

  factory HistoriqueEvent.fromMap(Map<String, dynamic> map) {
    return HistoriqueEvent(
      historiqueId: map['historique_id'] as int? ?? 0,
      factureId: map['facture_id'] as int? ?? 0,
      planningDetailId: map['planning_detail_id'] as int?,
      signalementId: map['signalement_id'] as int?,
      date: map['date'] != null
          ? DateTime.tryParse(map['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      contenu: map['description'] ?? map['contenu'] ?? '', // Support des alias SQL
      issue: map['issue'] as String?,
      action: map['action'] as String? ?? 'Aucune',
      datePlanification: map['date_planification'] != null
          ? DateTime.tryParse(map['date_planification'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'historique_id': historiqueId,
      'facture_id': factureId,
      'planning_detail_id': planningDetailId,
      'signalement_id': signalementId,
      'date_historique': date.toIso8601String(),
      'contenu': contenu,
      'issue': issue,
      'action': action,
    };
  }

  /// Alias pour la description (compatibilité UI)
  String get description => contenu;

  /// Détails formatés (compatibilité UI)
  String get details => '${issue ?? ''} | Action: $action'.trim();

  /// Icône basée sur le contenu ou l'état
  String get icon => issue != null && issue!.isNotEmpty ? '⚠️' : '✅';

  /// Couleur basée sur la présence d'un problème
  int get colorValue => (issue != null && issue!.isNotEmpty) 
      ? 0xFFF44336 // Rouge (Erreur/Issue)
      : 0xFF4CAF50; // Vert (Succès)

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'Il y a ${difference.inMinutes} min';
      }
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  String toString() {
    return 'Historique(id: $historiqueId, date: $date, contenu: $contenu)';
  }
}
