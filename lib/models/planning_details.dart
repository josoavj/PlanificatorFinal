class PlanningDetails {
  final int planningDetailId;
  final int planningId;
  final DateTime datePlanification;
  final String statut; // 'À venir', 'Effectué'

  PlanningDetails({
    required this.planningDetailId,
    required this.planningId,
    required this.datePlanification,
    this.statut = 'À venir',
  });

  // Serialization from JSON (MySQL result)
  factory PlanningDetails.fromJson(Map<String, dynamic> json) {
    return PlanningDetails(
      planningDetailId: json['planning_detail_id'] as int? ?? 0,
      planningId: json['planning_id'] as int? ?? 0,
      datePlanification: json['date_planification'] != null
          ? DateTime.parse(json['date_planification'].toString())
          : DateTime.now(),
      statut: json['statut'] as String? ?? 'À venir',
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'planning_detail_id': planningDetailId,
      'planning_id': planningId,
      'date_planification': datePlanification.toIso8601String().split('T')[0],
      'statut': statut,
    };
  }

  // Check if date is today
  bool get isToday {
    final now = DateTime.now();
    return datePlanification.year == now.year &&
        datePlanification.month == now.month &&
        datePlanification.day == now.day;
  }

  // Check if date is upcoming
  bool get isUpcoming => datePlanification.isAfter(DateTime.now());

  // Check if overdue
  bool get isOverdue =>
      statut == 'À venir' && datePlanification.isBefore(DateTime.now());

  // Copy with modifications
  PlanningDetails copyWith({
    int? planningDetailId,
    int? planningId,
    DateTime? datePlanification,
    String? statut,
  }) {
    return PlanningDetails(
      planningDetailId: planningDetailId ?? this.planningDetailId,
      planningId: planningId ?? this.planningId,
      datePlanification: datePlanification ?? this.datePlanification,
      statut: statut ?? this.statut,
    );
  }

  @override
  String toString() =>
      'PlanningDetails(planningDetailId: $planningDetailId, planning: $planningId, date: $datePlanification, statut: $statut)';
}
