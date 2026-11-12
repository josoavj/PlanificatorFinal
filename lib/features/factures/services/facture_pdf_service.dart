import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/facture.dart';

/// Service dédié à la génération et impression des factures au format PDF.
class FacturePdfService {
  /// Génère le document PDF pour une facture unique.
  static Future<Uint8List> buildSingleInvoicePdf(
    PdfPageFormat format,
    Facture facture,
  ) async {
    final document = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');

    document.addPage(
      pw.Page(
        pageFormat: format,
        build: (_) => pw.Padding(
          padding: const pw.EdgeInsets.all(32),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'FACTURE #${facture.factureId}',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 24),
              pw.Text('Date : ${dateFormat.format(facture.dateTraitement)}'),
              pw.Text('Client : ${facture.clientNom ?? 'Inconnu'}'),
              pw.Text('État : ${facture.isPaid ? 'Payée' : 'Non payée'}'),
              if (facture.referenceFacture?.isNotEmpty ?? false)
                pw.Text('Référence : ${facture.referenceFacture}'),
              pw.Divider(),
              pw.SizedBox(height: 12),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Total',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    facture.montantFormatted,
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    return document.save();
  }

  /// Génère un document PDF récapitulatif pour un groupe de factures.
  static Future<Uint8List> buildGroupInvoicePdf(
    PdfPageFormat format,
    String groupTitle,
    List<Facture> factures,
  ) async {
    final document = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');
    final numberFormat = NumberFormat('#,###', 'fr_FR');

    int total = 0;
    for (final f in factures) {
      total += f.montant;
    }

    document.addPage(
      pw.MultiPage(
        pageFormat: format,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'RÉCAPITULATIF DE FACTURES',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  dateFormat.format(DateTime.now()),
                  style: const pw.TextStyle(color: PdfColors.grey700),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Groupe : $groupTitle',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: ['ID', 'Date', 'Axe / Réf', 'État', 'Montant'],
            data: factures
                .map(
                  (f) => [
                    '#${f.factureId}',
                    dateFormat.format(f.dateTraitement),
                    f.axe.isNotEmpty ? f.axe : f.referenceFacture,
                    f.isPaid ? 'Payée' : 'Non payée',
                    f.montantFormatted,
                  ],
                )
                .toList(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
            cellAlignment: pw.Alignment.centerLeft,
            cellAlignments: {4: pw.Alignment.centerRight},
          ),
          pw.SizedBox(height: 20),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text(
                'Total général : ',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                '${numberFormat.format(total)} Ar',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return document.save();
  }

  /// Lance la prévisualisation et l'impression système pour une facture unique.
  static Future<void> printFacture(Facture facture) async {
    await Printing.layoutPdf(
      onLayout: (format) => buildSingleInvoicePdf(format, facture),
    );
  }

  /// Lance la prévisualisation et l'impression pour un groupe de factures.
  static Future<void> printGroupFactures(
    String groupTitle,
    List<Facture> factures,
  ) async {
    await Printing.layoutPdf(
      onLayout: (format) => buildGroupInvoicePdf(format, groupTitle, factures),
    );
  }
}
