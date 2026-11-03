class WeeklyDistribution {
  static int daysToAdd({required int redondance, required int stepIndex}) {
    switch (redondance) {
      case -1: // Hebdomadaire
        return 7;
      case -2: // Toutes les 2 semaines
        return 14;
      case -3: // 2 fois par semaine
        return (stepIndex % 2 == 0) ? 3 : 4;
      case -4: // 3 fois par semaine
        // Répartition: Lu -> Mer (+2), Mer -> Ven (+2), Ven -> Lu (+3)
        final mod = stepIndex % 3;
        return (mod == 2) ? 3 : 2;
      default:
        return 7;
    }
  }
}
