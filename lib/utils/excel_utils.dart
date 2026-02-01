import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:planificator/services/logging_service.dart';

final _logger = createLoggerWithFileOutput(name: 'excel_utils');

class FolderManager {
  static List<Directory> initDesktopStructure() {
    try {
      final desktop = _getDesktopPath();
      _logger.i('📁 Desktop trouvé: ${desktop.path}');

      final dossiers = ["Factures", "Traitements"];
      List<Directory> paths = [];

      for (var nom in dossiers) {
        final dir = Directory(p.join(desktop.path, nom));
        try {
          if (!dir.existsSync()) {
            dir.createSync(recursive: true);
            _logger.i(' Dossier créé: ${dir.path}');
          } else {
            _logger.d('ℹ️ Dossier existe déjà: ${dir.path}');
          }
          paths.add(dir);
        } catch (e) {
          _logger.e(' Erreur création dossier $nom: $e');
          // Créer dans un dossier de secours (Documents)
          final homeDir = Platform.isWindows
              ? (envVars['USERPROFILE'] ?? '')
              : (envVars['HOME'] ?? '');
          final fallbackDir = Directory(
            p.join(homeDir, 'Documents', 'Planificator', nom),
          );
          fallbackDir.createSync(recursive: true);
          _logger.i(' Dossier de secours créé: ${fallbackDir.path}');
          paths.add(fallbackDir);
        }
      }
      return paths;
    } catch (e) {
      _logger.e(' Erreur initDesktopStructure: $e');
      rethrow;
    }
  }

  static final Map<String, String> envVars = Platform.environment;

  static Directory _getDesktopPath() {
    String home = "";

    if (Platform.isWindows) {
      home = envVars['USERPROFILE'] ?? "";
    } else if (Platform.isLinux || Platform.isMacOS) {
      home = envVars['HOME'] ?? "";
    }

    if (home.isEmpty) {
      _logger.w(' HOME/USERPROFILE non trouvé');
      throw Exception('Cannot determine home directory');
    }

    _logger.i(' Home directory: $home');

    // Sur Windows, essayer Desktop d'abord
    var desktop = Directory(p.join(home, 'Desktop'));
    _logger.d(
      '🔍 Vérification Desktop: ${desktop.path} (existe: ${desktop.existsSync()})',
    );

    if (!desktop.existsSync()) {
      desktop = Directory(p.join(home, 'Bureau'));
      _logger.d(
        '🔍 Vérification Bureau: ${desktop.path} (existe: ${desktop.existsSync()})',
      );
    }

    if (!desktop.existsSync()) {
      // Si Bureau et Desktop n'existent pas, créer dans Documents
      desktop = Directory(p.join(home, 'Documents'));
      _logger.d(
        '🔍 Fallback Documents: ${desktop.path} (existe: ${desktop.existsSync()})',
      );
    }

    _logger.i(' Desktop path final: ${desktop.path}');
    return desktop;
  }
}

class ExcelService {
  final List<Directory> paths = FolderManager.initDesktopStructure();

  // Cache pour éviter les doublons de styles
  final Map<String, Style> _styleCache = {};

  // --- LOGIQUE COMMUNE POUR LE NETTOYAGE DU NOM (safe_client_name) ---
  String _getSafeName(String name) {
    return name
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'_+$'), '');
  }

  // --- 1. FONCTION : generate_comprehensive_facture_excel (Annuel) ---
  Future<String> generateComprehensiveFactureExcel(
    List<Map<String, dynamic>> data,
    String clientFullName,
  ) async {
    // Vider le cache avant de générer un nouveau fichier
    _styleCache.clear();

    final int reportPeriod = DateTime.now().year;
    final String safeName = _getSafeName(clientFullName);

    final Workbook workbook = Workbook();
    final Worksheet sheet = workbook.worksheets[0];
    sheet.name = "Factures $clientFullName $reportPeriod";

    int currentRow = 1;
    currentRow = _insertClientHeader(sheet, data, clientFullName, currentRow);

    // Titre fusionné
    sheet.getRangeByIndex(currentRow, 1, currentRow, 9).merge();
    sheet
        .getRangeByIndex(currentRow, 1)
        .setText("Rapport de Facturation pour la période : $reportPeriod");
    sheet.getRangeByIndex(currentRow, 1).cellStyle = _getHeaderStyle(workbook);
    currentRow += 2;

    currentRow = _insertMainTable(
      sheet,
      workbook,
      data,
      currentRow,
      isMonthly: false,
    );

    // Logique Totaux (Simule Pandas sum/groupby)
    _insertTotals(sheet, workbook, data, currentRow, isMonthly: false);

    return _saveFile(
      workbook,
      paths[0],
      "Rapport_Factures_${safeName}_$reportPeriod.xlsx",
    );
  }

  // --- 2. FONCTION : generer_facture_excel (Mensuel ou Annuel) ---
  Future<String> genererFactureExcel(
    List<Map<String, dynamic>> data,
    String clientFullName,
    int year,
    int month,
  ) async {
    // Vider le cache avant de générer un nouveau fichier
    _styleCache.clear();

    final String safeName = _getSafeName(clientFullName);

    final Workbook workbook = Workbook();
    final Worksheet sheet = workbook.worksheets[0];

    int currentRow = 1;
    currentRow = _insertClientHeader(sheet, data, clientFullName, currentRow);

    // Titre - varie selon que c'est un mois spécifique ou tous les mois
    String titleText;
    String filename;

    if (month == 0) {
      // Tous les mois (annuel)
      titleText = "Rapport de Facturation pour l'année : $year";
      filename = "$safeName-Annuel-$year.xlsx";
    } else {
      // Mois spécifique
      final String monthNameFr = DateFormat.MMMM(
        'fr_FR',
      ).format(DateTime(year, month)).toUpperCase();
      titleText = "Facture du mois de : $monthNameFr $year";
      filename = "$safeName-$monthNameFr-$year.xlsx";
    }

    sheet.getRangeByIndex(currentRow, 1, currentRow, 9).merge();
    sheet.getRangeByIndex(currentRow, 1).setText(titleText);
    sheet.getRangeByIndex(currentRow, 1).cellStyle = _getHeaderStyle(workbook);
    currentRow += 2;

    currentRow = _insertMainTable(
      sheet,
      workbook,
      data,
      currentRow,
      isMonthly: month != 0,
    );
    _insertTotals(sheet, workbook, data, currentRow, isMonthly: month != 0);

    return _saveFile(workbook, paths[0], filename);
  }

  // --- 3. FONCTION : generate_traitements_excel ---
  Future<String> generateTraitementsExcel(
    List<Map<String, dynamic>> data,
    int year,
    int month,
  ) async {
    // Vider le cache avant de générer un nouveau fichier
    _styleCache.clear();

    final String monthNameFr = DateFormat.MMMM(
      'fr_FR',
    ).format(DateTime(year, month)).toUpperCase();
    final Workbook workbook = Workbook();
    final Worksheet sheet = workbook.worksheets[0];

    // Titre
    sheet.getRangeByIndex(1, 1, 1, 7).merge();
    sheet
        .getRangeByIndex(1, 1)
        .setText("Rapport des Traitements du mois de $monthNameFr $year");
    sheet.getRangeByIndex(1, 1).cellStyle = _getHeaderStyle(workbook);

    sheet
        .getRangeByIndex(3, 1)
        .setText("Nombre total de traitements ce mois-ci : ${data.length}");
    sheet.getRangeByIndex(3, 1).cellStyle.bold = true;

    if (data.isEmpty) {
      sheet.getRangeByIndex(5, 1).setText("Aucun traitement trouvé.");
    } else {
      List<String> headers = data[0].keys.toList();
      // Écriture headers
      for (int i = 0; i < headers.length; i++) {
        var cell = sheet.getRangeByIndex(5, i + 1);
        cell.setText(headers[i]);
        cell.cellStyle = _getBoldBorderStyle(workbook);
      }
      // Données + Couleurs (Effectué = Vert, À venir = Rouge)
      for (int i = 0; i < data.length; i++) {
        String rowStatus = '';

        // D'abord, déterminer le statut de la ligne
        for (int j = 0; j < headers.length; j++) {
          if (headers[j] == 'Etat traitement') {
            rowStatus = data[i][headers[j]].toString();
            break;
          }
        }

        // Appliquer la couleur à toute la ligne selon le statut
        String backgroundColor = '';
        if (rowStatus == 'Effectué') {
          backgroundColor = '#C6EFCE'; // Vert pour effectué
        } else if (rowStatus == 'À venir') {
          backgroundColor = '#FFC7CE'; // Rouge pour à venir
        }

        // Appliquer la couleur à toutes les cellules de la ligne
        for (int j = 0; j < headers.length; j++) {
          var cell = sheet.getRangeByIndex(6 + i, j + 1);
          var value = data[i][headers[j]];
          cell.setValue(value);
          cell.cellStyle.borders.all.lineStyle = LineStyle.thin;

          if (backgroundColor.isNotEmpty) {
            cell.cellStyle.backColor = backgroundColor;
          }
        }
      }
    }

    for (int i = 1; i <= 10; i++) {
      sheet.autoFitColumn(i);
    }
    return _saveFile(workbook, paths[1], "traitements-$monthNameFr-$year.xlsx");
  }

  // --- MÉTHODES PRIVÉES (LOGIQUE INTERNE) ---

  int _insertClientHeader(
    Worksheet sheet,
    List<Map<String, dynamic>> data,
    String clientFullName,
    int row,
  ) {
    if (data.isEmpty) return row;
    final info = data[0];
    String displayName = "${info['client_nom']} ${info['client_prenom']}";
    if (info['client_categorie'] != 'Particulier') {
      displayName =
          "${info['client_nom']} (Responsable: ${info['client_prenom'] ?? 'N/A'})";
    }

    final List<List<String>> rows = [
      ["Client :", displayName],
      ["N° Contrat :", info['Référence Contrat']?.toString() ?? 'N/A'],
      ["Adresse :", info['client_adresse']?.toString() ?? 'N/A'],
      ["Téléphone :", info['client_telephone']?.toString() ?? 'N/A'],
      ["Catégorie Client :", info['client_categorie']?.toString() ?? 'N/A'],
      ["Axe Client :", info['client_axe']?.toString() ?? 'N/A'],
    ];

    for (var r in rows) {
      sheet.getRangeByIndex(row, 1).setText(r[0]);
      sheet.getRangeByIndex(row, 1).cellStyle.bold = true;
      sheet.getRangeByIndex(row, 2).setText(r[1]);
      row++;
    }
    return row + 1;
  }

  int _insertMainTable(
    Worksheet sheet,
    Workbook wb,
    List<Map<String, dynamic>> data,
    int startRow, {
    required bool isMonthly,
  }) {
    final headers = [
      'Numéro Facture',
      'Date de Planification',
      'Date de Facturation',
      'Type de Traitement',
      'Etat du Planning',
      'Mode de Paiement',
      'Détails Paiement',
      'Etat de Paiement',
      'Montant Facturé',
    ];

    for (int i = 0; i < headers.length; i++) {
      var cell = sheet.getRangeByIndex(startRow, i + 1);
      cell.setText(headers[i]);
      cell.cellStyle = _getBoldBorderStyle(wb);
    }

    int rIdx = startRow + 1;
    for (var item in data) {
      String details = _formatPaymentDetails(item);
      List<dynamic> rowData = [
        item['Numéro Facture'] ?? "Aucun",
        item['Date de Planification'] ?? 'N/A',
        isMonthly ? item['Date de traitement'] : item['Date de Facturation'],
        isMonthly ? item['Traitement (Type)'] : item['Type de Traitement'],
        isMonthly ? item['Etat traitement'] : item['Etat du Planning'],
        item['Mode de Paiement'] ?? 'N/A',
        details,
        isMonthly
            ? item['Etat paiement (Payée ou non)']
            : item['Etat de Paiement'],
        isMonthly ? item['montant_facture'] : item['Montant Facturé'],
      ];

      // Déterminer le statut de paiement pour la coloration
      String status =
          (isMonthly
                  ? item['Etat paiement (Payée ou non)']
                  : item['Etat de Paiement'])
              .toString();

      // Appliquer la couleur et les formats à chaque cellule de la ligne
      for (int cIdx = 0; cIdx < rowData.length; cIdx++) {
        var cell = sheet.getRangeByIndex(rIdx, cIdx + 1);
        var value = rowData[cIdx];

        // Créer le style avec les propriétés appropriées
        final cellStyle = wb.styles.add('row_style_$rIdx$cIdx');
        cellStyle.borders.all.lineStyle = LineStyle.thin;

        // Appliquer la couleur de fond selon le statut
        if (status == 'Payé' || status == 'Payée') {
          cellStyle.backColor = '#C6EFCE'; // Vert pour payé
        } else {
          cellStyle.backColor = '#FFC7CE'; // Rouge pour non payé/à venir
        }

        // Formater les dates (colonnes 1 et 2)
        if (cIdx == 1 || cIdx == 2) {
          // Colonnes de dates
          if (value is DateTime) {
            cell.setDateTime(value);
            cellStyle.numberFormat = 'dd/mm/yy';
          } else if (value is String && value != 'N/A') {
            try {
              final date = DateTime.parse(value);
              cell.setDateTime(date);
              cellStyle.numberFormat = 'dd/mm/yy';
            } catch (e) {
              cell.setText(value.toString());
            }
          } else {
            cell.setText(value?.toString() ?? 'N/A');
          }
        }
        // Formater les montants (colonne 8)
        else if (cIdx == 8) {
          cell.setText(_formatMontant(value));
        } else {
          cell.setValue(value);
        }

        cell.cellStyle = cellStyle;
      }
      rIdx++;
    }
    return rIdx + 1;
  }

  void _insertTotals(
    Worksheet sheet,
    Workbook wb,
    List<Map<String, dynamic>> data,
    int row, {
    required bool isMonthly,
  }) {
    if (data.isEmpty) return;

    final String amountKey = isMonthly ? 'montant_facture' : 'Montant Facturé';
    final String statusKey = isMonthly
        ? 'Etat paiement (Payée ou non)'
        : 'Etat de Paiement';
    final String treatmentKey = isMonthly
        ? 'Traitement (Type)'
        : 'Type de Traitement';

    // Calcul des totaux généraux - convertir en double/num
    double total = data.fold(0.0, (prev, e) {
      final amount = e[amountKey];
      final numAmount = (amount is num) ? amount.toDouble() : 0.0;
      return prev + numAmount;
    });

    double paid = data
        .where((e) => e[statusKey] == 'Payé' || e[statusKey] == 'Payée')
        .fold(0.0, (prev, e) {
          final amount = e[amountKey];
          final numAmount = (amount is num) ? amount.toDouble() : 0.0;
          return prev + numAmount;
        });

    // Grouper par type de traitement
    final Map<String, double> totalByTreatment = {};
    for (var item in data) {
      final treatment = item[treatmentKey]?.toString() ?? 'N/A';
      final amount = item[amountKey];
      final numAmount = (amount is num) ? amount.toDouble() : 0.0;
      totalByTreatment[treatment] =
          (totalByTreatment[treatment] ?? 0) + numAmount;
    }

    // Ajouter une ligne vide
    row++;

    // Afficher les totaux par type de traitement
    if (totalByTreatment.isNotEmpty) {
      sheet.getRangeByIndex(row, 1).setText("Totaux par Type de Traitement :");
      sheet.getRangeByIndex(row, 1).cellStyle.bold = true;
      row += 2;

      for (var entry in totalByTreatment.entries) {
        sheet.getRangeByIndex(row, 1).setText(entry.key);
        sheet.getRangeByIndex(row, 1).cellStyle.bold = true;
        sheet.getRangeByIndex(row, 9).setText(_formatMontant(entry.value));
        sheet.getRangeByIndex(row, 9).cellStyle.bold = true;
        sheet.getRangeByIndex(row, 9).cellStyle.backColor = '#E7E6E6';
        row++;
      }
    }

    // Ligne de séparation
    row++;

    // Afficher les totaux généraux
    sheet.getRangeByIndex(row, 1).setText("Montant Total Facturé :");
    sheet.getRangeByIndex(row, 1).cellStyle.bold = true;
    sheet.getRangeByIndex(row, 9).setText(_formatMontant(total));
    sheet.getRangeByIndex(row, 9).cellStyle.bold = true;
    sheet.getRangeByIndex(row, 9).cellStyle.backColor = '#FFF2CC';
    row++;

    sheet.getRangeByIndex(row, 1).setText("Montant Total Payé :");
    sheet.getRangeByIndex(row, 1).cellStyle.bold = true;
    sheet.getRangeByIndex(row, 9).setText(_formatMontant(paid));
    sheet.getRangeByIndex(row, 9).cellStyle.bold = true;
    sheet.getRangeByIndex(row, 9).cellStyle.backColor = '#C6EFCE';

    // Auto-fit à la fin
    for (int i = 1; i <= 9; i++) {
      sheet.autoFitColumn(i);
    }
  }

  String _formatPaymentDetails(Map<String, dynamic> item) {
    // Utiliser la clé 'Détails Paiement' déjà calculée dans export_screen.dart
    return item['Détails Paiement'] ?? 'N/A';
  }

  /// Formate un montant au format: 90 000 Ar, 120 000 Ar, etc.
  String _formatMontant(dynamic amount) {
    if (amount == null) return 'N/A';

    // Convertir en int correctement (gère les int et les double)
    int intAmount = 0;
    if (amount is int) {
      intAmount = amount;
    } else if (amount is double) {
      intAmount = amount.toInt();
    } else {
      intAmount = int.tryParse(amount.toString()) ?? 0;
    }

    final formatter = NumberFormat('#,##0', 'fr_FR');
    return '${formatter.format(intAmount)} Ar';
  }

  Style _getHeaderStyle(Workbook wb) {
    // Vérifier le cache d'abord
    if (_styleCache.containsKey('header')) {
      return _styleCache['header']!;
    }

    // Si pas en cache, créer et mettre en cache
    try {
      final style = wb.styles['h']!;
      _styleCache['header'] = style;
      return style;
    } catch (e) {
      // Le style n'existe pas, le créer
      Style s = wb.styles.add('h');
      s.bold = true;
      s.fontSize = 14;
      s.hAlign = HAlignType.center;
      _styleCache['header'] = s;
      return s;
    }
  }

  Style _getBoldBorderStyle(Workbook wb) {
    // Vérifier le cache d'abord
    if (_styleCache.containsKey('boldBorder')) {
      return _styleCache['boldBorder']!;
    }

    // Si pas en cache, créer et mettre en cache
    try {
      final style = wb.styles['bold_border']!;
      _styleCache['boldBorder'] = style;
      return style;
    } catch (e) {
      // Le style n'existe pas, le créer
      Style s = wb.styles.add('bold_border');
      s.bold = true;
      s.borders.all.lineStyle = LineStyle.thin;
      _styleCache['boldBorder'] = s;
      return s;
    }
  }

  String _saveFile(Workbook wb, Directory dir, String fileName) {
    // Ajouter la signature à la première feuille
    try {
      _addSignatureToSheet(wb.worksheets[0], wb);
    } catch (e) {
      _logger.w(' Erreur lors de l\'ajout de la signature: $e');
    }

    final List<int> bytes = wb.saveAsStream();
    final String filePath = p.join(dir.path, fileName);
    File(filePath).writeAsBytesSync(bytes);
    wb.dispose();
    _logger.i(' Fichier sauvegardé: $filePath');
    return filePath;
  }

  /// Ajoute une signature de pied de page à une feuille
  void _addSignatureToSheet(Worksheet sheet, Workbook wb) {
    try {
      // Trouver la dernière ligne avec du contenu
      int lastRow = sheet.getLastRow();
      int signatureRow = lastRow + 2; // Laisser une ligne vide

      // Créer un style pour la signature (petit, gris, italique)
      final Style signatureStyle = wb.styles.add(
        'signature_${DateTime.now().millisecondsSinceEpoch}',
      );
      signatureStyle.fontSize = 9;
      signatureStyle.fontColor = '#808080';
      signatureStyle.italic = true;

      // Ajouter la signature
      final signatureCell = sheet.getRangeByIndex(signatureRow, 1);
      signatureCell.setText('Données générées via Planificator v2.1.1');
      signatureCell.cellStyle = signatureStyle;
    } catch (e) {
      _logger.w(' Impossible d\'ajouter la signature: $e');
      // Ne pas bloquer si la signature échoue
    }
  }

  /// Méthode générique pour créer des exports Excel
  Future<String> genererExcelGenerique({
    required String title,
    required List<String> headers,
    required List<List<dynamic>> data,
    required String fileName,
  }) async {
    final Workbook workbook = Workbook();
    final Worksheet sheet = workbook.worksheets[0];

    final Style headerStyle = workbook.styles.add('headerStyle');
    headerStyle.bold = true;
    headerStyle.fontSize = 12;
    headerStyle.hAlign = HAlignType.center;
    headerStyle.backColor = '#4472C4';
    headerStyle.fontColor = '#FFFFFF';

    final Style boldStyle = workbook.styles.add('boldStyle');
    boldStyle.bold = true;

    int currentRow = 1;

    // Titre
    sheet.getRangeByIndex(currentRow, 1, currentRow, headers.length).merge();
    sheet.getRangeByIndex(currentRow, 1).setText(title);
    sheet.getRangeByIndex(currentRow, 1).cellStyle = headerStyle;
    currentRow += 2;

    // Headers
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.getRangeByIndex(currentRow, i + 1);
      cell.setText(headers[i]);
      cell.cellStyle = headerStyle;
      cell.cellStyle.borders.all.lineStyle = LineStyle.thin;
    }
    currentRow++;

    // Données
    for (var row in data) {
      for (int i = 0; i < row.length; i++) {
        final cell = sheet.getRangeByIndex(currentRow, i + 1);
        cell.setValue(row[i]);
        cell.cellStyle.borders.all.lineStyle = LineStyle.thin;
      }
      currentRow++;
    }

    // Sauvegarde
    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    final folder2 = Directory(
      p.join(FolderManager._getDesktopPath().path, 'Exports'),
    );
    if (!folder2.existsSync()) {
      folder2.createSync(recursive: true);
    }

    final finalPath = p.join(folder2.path, '$fileName.xlsx');
    await File(finalPath).writeAsBytes(bytes);
    return finalPath;
  }
}
