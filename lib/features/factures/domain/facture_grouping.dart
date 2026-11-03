import '../models/facture.dart';

class FactureGrouping {
  static Map<String, List<Facture>> byClientAndTreatment(
    Iterable<Facture> factures,
  ) {
    final grouped = <String, List<Facture>>{};
    for (final facture in factures) {
      final key =
          '${facture.clientFullName} - ${facture.typeTreatment ?? 'N/A'}';
      grouped.putIfAbsent(key, () => []).add(facture);
    }
    return grouped;
  }

  static int totalPaid(Iterable<Facture> factures) {
    return factures
        .where((facture) => facture.isPaid)
        .fold(0, (sum, facture) => sum + facture.montant);
  }

  static int totalUnpaid(Iterable<Facture> factures) {
    return factures
        .where((facture) => !facture.isPaid)
        .fold(0, (sum, facture) => sum + facture.montant);
  }
}
