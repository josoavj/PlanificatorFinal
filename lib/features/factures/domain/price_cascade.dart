import 'package:logger/logger.dart';

import '../../../core/database/transaction_runner.dart';
import '../models/facture.dart';
import '../../../core/database/sql/sql_queries.dart';

class PriceCascade {
  final TransactionRunner transactionRunner;
  final List<Facture> factures;
  final Logger logger;

  const PriceCascade({
    required this.transactionRunner,
    required this.factures,
    required this.logger,
  });

  Future<void> apply({
    required int factureId,
    required int oldMontant,
    required int newMontant,
  }) async {
    final factureRows = await transactionRunner.database.queryOne(
      SqlQueries.getFactureAndTreatmentInfo,
      params: [factureId],
    );
    if (factureRows == null) {
      throw Exception('Facture non trouvée');
    }

    final dateTraitement = factureRows['date_traitement'];
    final traitementId = factureRows['traitement_id'];
    if (dateTraitement == null || traitementId == null) {
      throw Exception('Données incomplètes pour la facture');
    }

    final prixDiff = newMontant - oldMontant;
    logger.i(
      ' Différence de prix: $prixDiff Ar (ancien: $oldMontant, nouveau: $newMontant)',
    );

    await transactionRunner.run<void>((conn) async {
      await conn.query(SqlQueries.massUpdateFutureFacturePrices, [
        prixDiff,
        traitementId,
        dateTraitement,
      ]);

      final otherFactures = await conn.query(
        SqlQueries.getOtherFacturesByTreatmentFromDate,
        [traitementId, dateTraitement],
      );

      final now = DateTime.now().toIso8601String();
      for (final row in otherFactures) {
        final fId = row['facture_id'] as int;
        final mAncien = row['montant'] as int;
        final mNouveau = mAncien + prixDiff;

        await conn.query(SqlQueries.createPriceHistoryEntry, [
          fId,
          mAncien,
          mNouveau,
          now,
        ]);
      }
    });

    final dtRef = DateTime.parse(dateTraitement.toString());
    for (var i = 0; i < factures.length; i++) {
      final facture = factures[i];
      if (facture.traitementId == traitementId &&
          facture.dateTraitement.compareTo(dtRef) >= 0 &&
          !facture.isPaid) {
        factures[i] = facture.copyWith(montant: facture.montant + prixDiff);
      }
    }

    logger.i(' Mise à jour locale terminée pour traitement $traitementId');
  }
}
