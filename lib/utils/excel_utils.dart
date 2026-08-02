import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:planificator/services/logging_service.dart';

final _logger = createLoggerWithFileOutput(name: 'excel_utils');

class FolderManager {
  static const String _storageKey = 'custom_export_path';

  /// Initialise la structure des dossiers à l'emplacement configuré ou par défaut
  static Future<List<Directory>> initDesktopStructure() async {
    try {
      final baseDir = await getExportBasePath();
      _logger.i('📁 Dossier base export: ${baseDir.path}');

      final dossiers = ['Factures', 'Traitements', 'Exports'];
      List<Directory> paths = [];

      for (var nom in dossiers) {
        final dir = Directory(p.join(baseDir.path, nom));
        try {
          if (!dir.existsSync()) {
            dir.createSync(recursive: true);
            _logger.i(' Dossier créé: ${dir.path}');
          }
          paths.add(dir);
        } catch (e) {
          _logger.e(' Erreur création dossier $nom: $e');
          // Fallback ultime dans Documents si même le personnalisé échoue
          final home = _getHomeDir();
          final fallbackDir = Directory(p.join(home, 'Documents', 'Planificator', nom));
          fallbackDir.createSync(recursive: true);
          paths.add(fallbackDir);
        }
      }
      return paths;
    } catch (e) {
      _logger.e(' Erreur initDesktopStructure: $e');
      rethrow;
    }
  }

  /// Récupère le chemin de base actuel (Persistant)
  static Future<Directory> getExportBasePath() async {
    final prefs = await SharedPreferences.getInstance();
    final customPath = prefs.getString(_storageKey);

    if (customPath != null && customPath.isNotEmpty) {
      final dir = Directory(customPath);
      if (dir.existsSync()) {
        return Directory(p.join(customPath, 'Planificator'));
      }
    }

    // Par défaut sur le Bureau/Planificator
    return Directory(p.join(_getDesktopPath().path, 'Planificator'));
  }

  /// Sauvegarde un nouveau chemin personnalisé
  static Future<void> setCustomPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, path);
    // Recréer la structure immédiatement
    await initDesktopStructure();
  }

  /// Réinitialise au chemin par défaut (Bureau)
  static Future<void> resetToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    await initDesktopStructure();
  }

  static String _getHomeDir() {
    if (Platform.isWindows) return Platform.environment['USERPROFILE'] ?? '';
    return Platform.environment['HOME'] ?? '';
  }

  static Directory _getDesktopPath() {
    final home = _getHomeDir();
    if (home.isEmpty) throw Exception('Cannot determine home directory');

    var desktop = Directory(p.join(home, 'Desktop'));
    if (!desktop.existsSync()) desktop = Directory(p.join(home, 'Bureau'));
    if (!desktop.existsSync()) desktop = Directory(p.join(home, 'Documents'));
    
    return desktop;
  }
}

class ExcelService {
  /// Nettoie un nom pour être utilisable comme nom de fichier
  static String getSafeName(String name) {
    return name
        .trim()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'_+$'), '');
  }

  /// Génère dynamiquement les chemins pour chaque export
  Future<List<Directory>> _getPaths() async => await FolderManager.initDesktopStructure();

  final Map<String, Style> _styleCache = {};

  // --- 1. FONCTION : generate_comprehensive_facture_excel (Annuel) ---
  Future<String> generateComprehensiveFactureExcel(
    List<Map<String, dynamic>> data,
    String clientFullName,
  ) async {
    _styleCache.clear();
    final paths = await _getPaths();

    final int reportPeriod = DateTime.now().year;
    final String safeName = ExcelService.getSafeName(clientFullName);

    final Workbook workbook = Workbook();
    final Worksheet sheet = workbook.worksheets[0];
    sheet.name = 'Factures $clientFullName $reportPeriod';

    int currentRow = 1;
    currentRow = _insertClientHeader(sheet, data, clientFullName, currentRow);

    sheet.getRangeByIndex(currentRow, 1, currentRow, 9).merge();
    sheet.getRangeByIndex(currentRow, 1).setText('Rapport de Facturation pour la période : $reportPeriod');
    sheet.getRangeByIndex(currentRow, 1).cellStyle = _getHeaderStyle(workbook);
    currentRow += 2;

    currentRow = _insertMainTable(sheet, workbook, data, currentRow, isMonthly: false);
    _insertTotals(sheet, workbook, data, currentRow, isMonthly: false);

    return _saveFile(workbook, paths[0], 'Rapport_Factures_${safeName}_$reportPeriod.xlsx');
  }

  // --- 2. FONCTION : generer_facture_excel (Mensuel ou Annuel) ---
  Future<String> genererFactureExcel(
    List<Map<String, dynamic>> data,
    String clientFullName,
    int year,
    int month,
  ) async {
    _styleCache.clear();
    final paths = await _getPaths();

    final String safeName = ExcelService.getSafeName(clientFullName);
    final Workbook workbook = Workbook();
    final Worksheet sheet = workbook.worksheets[0];

    int currentRow = 1;
    currentRow = _insertClientHeader(sheet, data, clientFullName, currentRow);

    String titleText;
    String filename;

    if (month == 0) {
      titleText = "Rapport de Facturation pour l'année : $year";
      filename = '$safeName-Annuel-$year.xlsx';
    } else {
      final String monthNameFr = DateFormat.MMMM('fr_FR').format(DateTime(year, month)).toUpperCase();
      titleText = 'Facture du mois de : $monthNameFr $year';
      filename = '$safeName-$monthNameFr-$year.xlsx';
    }

    sheet.getRangeByIndex(currentRow, 1, currentRow, 9).merge();
    sheet.getRangeByIndex(currentRow, 1).setText(titleText);
    sheet.getRangeByIndex(currentRow, 1).cellStyle = _getHeaderStyle(workbook);
    currentRow += 2;

    currentRow = _insertMainTable(sheet, workbook, data, currentRow, isMonthly: month != 0);
    _insertTotals(sheet, workbook, data, currentRow, isMonthly: month != 0);

    return _saveFile(workbook, paths[0], filename);
  }

  // --- 3. FONCTION : generate_traitements_excel ---
  Future<String> generateTraitementsExcel(
    List<Map<String, dynamic>> data,
    int year,
    int month,
  ) async {
    _styleCache.clear();
    final paths = await _getPaths();

    final String monthNameFr = DateFormat.MMMM('fr_FR').format(DateTime(year, month)).toUpperCase();
    final Workbook workbook = Workbook();
    final Worksheet sheet = workbook.worksheets[0];

    sheet.getRangeByIndex(1, 1, 1, 7).merge();
    sheet.getRangeByIndex(1, 1).setText('Rapport des Traitements du mois de $monthNameFr $year');
    sheet.getRangeByIndex(1, 1).cellStyle = _getHeaderStyle(workbook);

    sheet.getRangeByIndex(3, 1).setText('Nombre total de traitements ce mois-ci : ${data.length}');
    sheet.getRangeByIndex(3, 1).cellStyle.bold = true;

    if (data.isEmpty) {
      sheet.getRangeByIndex(5, 1).setText('Aucun traitement trouvé.');
    } else {
      List<String> headers = data[0].keys.toList();
      for (int i = 0; i < headers.length; i++) {
        var cell = sheet.getRangeByIndex(5, i + 1);
        cell.setText(headers[i]);
        cell.cellStyle = _getBoldBorderStyle(workbook);
      }
      for (int i = 0; i < data.length; i++) {
        String rowStatus = '';
        for (int j = 0; j < headers.length; j++) {
          if (headers[j] == 'Etat traitement') {
            rowStatus = data[i][headers[j]].toString();
            break;
          }
        }

        String backgroundColor = '';
        if (rowStatus == 'Effectué') {
          backgroundColor = '#C6EFCE';
        } else if (rowStatus == 'À venir') {
          backgroundColor = '#FFC7CE';
        }

        for (int j = 0; j < headers.length; j++) {
          var cell = sheet.getRangeByIndex(6 + i, j + 1);
          var value = data[i][headers[j]];
          cell.setValue(value);
          cell.cellStyle.borders.all.lineStyle = LineStyle.thin;
          if (backgroundColor.isNotEmpty) cell.cellStyle.backColor = backgroundColor;
        }
      }
    }

    for (int i = 1; i <= 10; i++) {
      sheet.autoFitColumn(i);
    }
    return _saveFile(workbook, paths[1], 'traitements-$monthNameFr-$year.xlsx');
  }

  // --- HELPERS INTERNES ---

  int _insertClientHeader(Worksheet sheet, List<Map<String, dynamic>> data, String clientFullName, int row) {
    if (data.isEmpty) return row;
    final info = data[0];
    String displayName = '${info['client_nom']} ${info['client_prenom']}';
    if (info['client_categorie'] != 'Particulier') {
      displayName = '${info['client_nom']} (Responsable: ${info['client_prenom'] ?? 'N/A'})';
    }

    final List<List<String>> rows = [
      ['Client :', displayName],
      ['N° Contrat :', info['Référence Contrat']?.toString() ?? 'N/A'],
      ['Adresse :', info['client_adresse']?.toString() ?? 'N/A'],
      ['Téléphone :', info['client_telephone']?.toString() ?? 'N/A'],
      ['Catégorie Client :', info['client_categorie']?.toString() ?? 'N/A'],
      ['Axe Client :', info['client_axe']?.toString() ?? 'N/A'],
    ];

    for (var r in rows) {
      sheet.getRangeByIndex(row, 1).setText(r[0]);
      sheet.getRangeByIndex(row, 1).cellStyle.bold = true;
      sheet.getRangeByIndex(row, 2).setText(r[1]);
      row++;
    }
    return row + 1;
  }

  int _insertMainTable(Worksheet sheet, Workbook wb, List<Map<String, dynamic>> data, int startRow, {required bool isMonthly}) {
    final headers = ['Numéro Facture', 'Date de Planification', 'Date de Facturation', 'Type de Traitement', 'Etat du Planning', 'Mode de Paiement', 'Détails Paiement', 'Etat de Paiement', 'Montant Facturé'];
    for (int i = 0; i < headers.length; i++) {
      var cell = sheet.getRangeByIndex(startRow, i + 1);
      cell.setText(headers[i]);
      cell.cellStyle = _getBoldBorderStyle(wb);
    }

    int rIdx = startRow + 1;
    for (var item in data) {
      String details = item['Détails Paiement'] ?? 'N/A';
      List<dynamic> rowData = [
        item['Numéro Facture'] ?? 'Aucun',
        item['Date de Planification'] ?? 'N/A',
        isMonthly ? item['Date de traitement'] : item['Date de Facturation'],
        isMonthly ? item['Traitement (Type)'] : item['Type de Traitement'],
        isMonthly ? item['Etat traitement'] : item['Etat du Planning'],
        item['Mode de Paiement'] ?? 'N/A',
        details,
        isMonthly ? item['Etat paiement (Payée ou non)'] : item['Etat de Paiement'],
        isMonthly ? item['montant_facture'] : item['Montant Facturé'],
      ];

      String status = (isMonthly ? item['Etat paiement (Payée ou non)'] : item['Etat de Paiement']).toString();

      for (int cIdx = 0; cIdx < rowData.length; cIdx++) {
        var cell = sheet.getRangeByIndex(rIdx, cIdx + 1);
        var value = rowData[cIdx];
        final cellStyle = wb.styles.add('row_style_$rIdx$cIdx');
        cellStyle.borders.all.lineStyle = LineStyle.thin;
        cellStyle.backColor = (status == 'Payé' || status == 'Payée') ? '#C6EFCE' : '#FFC7CE';

        if (cIdx == 1 || cIdx == 2) {
          if (value is DateTime) { cell.setDateTime(value); cellStyle.numberFormat = 'dd/mm/yy'; }
          else if (value is String && value != 'N/A') { try { final date = DateTime.parse(value); cell.setDateTime(date); cellStyle.numberFormat = 'dd/mm/yy'; } catch (e) { cell.setText(value.toString()); } }
          else { cell.setText(value?.toString() ?? 'N/A'); }
        }
        else if (cIdx == 8) { cell.setText(_formatMontant(value)); }
        else { cell.setValue(value); }
        cell.cellStyle = cellStyle;
      }
      rIdx++;
    }
    return rIdx + 1;
  }

  void _insertTotals(Worksheet sheet, Workbook wb, List<Map<String, dynamic>> data, int row, {required bool isMonthly}) {
    if (data.isEmpty) return;
    final String amountKey = isMonthly ? 'montant_facture' : 'Montant Facturé';
    final String statusKey = isMonthly ? 'Etat paiement (Payée ou non)' : 'Etat de Paiement';
    final String treatmentKey = isMonthly ? 'Traitement (Type)' : 'Type de Traitement';

    double total = data.fold(0.0, (prev, e) => prev + ((e[amountKey] is num) ? e[amountKey].toDouble() : 0.0));
    double paid = data.where((e) => e[statusKey] == 'Payé' || e[statusKey] == 'Payée').fold(0.0, (prev, e) => prev + ((e[amountKey] is num) ? e[amountKey].toDouble() : 0.0));

    final Map<String, double> totalByTreatment = {};
    for (var item in data) {
      final treatment = item[treatmentKey]?.toString() ?? 'N/A';
      totalByTreatment[treatment] = (totalByTreatment[treatment] ?? 0) + ((item[amountKey] is num) ? item[amountKey].toDouble() : 0.0);
    }

    row++;
    if (totalByTreatment.isNotEmpty) {
      sheet.getRangeByIndex(row, 1).setText('Totaux par Type de Traitement :');
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

    row++;
    sheet.getRangeByIndex(row, 1).setText('Montant Total Facturé :');
    sheet.getRangeByIndex(row, 1).cellStyle.bold = true;
    sheet.getRangeByIndex(row, 9).setText(_formatMontant(total));
    sheet.getRangeByIndex(row, 9).cellStyle.bold = true;
    sheet.getRangeByIndex(row, 9).cellStyle.backColor = '#FFF2CC';
    row++;
    sheet.getRangeByIndex(row, 1).setText('Montant Total Payé :');
    sheet.getRangeByIndex(row, 1).cellStyle.bold = true;
    sheet.getRangeByIndex(row, 9).setText(_formatMontant(paid));
    sheet.getRangeByIndex(row, 9).cellStyle.bold = true;
    sheet.getRangeByIndex(row, 9).cellStyle.backColor = '#C6EFCE';

    for (int i = 1; i <= 9; i++) { sheet.autoFitColumn(i); }
  }

  String _formatMontant(dynamic amount) {
    if (amount == null) return 'N/A';
    int intAmount = (amount is num) ? amount.toInt() : (int.tryParse(amount.toString()) ?? 0);
    final formatter = NumberFormat('#,##0', 'fr_FR');
    return '${formatter.format(intAmount)} Ar';
  }

  Style _getHeaderStyle(Workbook wb) {
    if (_styleCache.containsKey('header')) return _styleCache['header']!;
    Style s = wb.styles.add('h');
    s.bold = true; s.fontSize = 14; s.hAlign = HAlignType.center;
    _styleCache['header'] = s;
    return s;
  }

  Style _getBoldBorderStyle(Workbook wb) {
    if (_styleCache.containsKey('boldBorder')) return _styleCache['boldBorder']!;
    Style s = wb.styles.add('bold_border');
    s.bold = true; s.borders.all.lineStyle = LineStyle.thin;
    _styleCache['boldBorder'] = s;
    return s;
  }

  String _saveFile(Workbook wb, Directory dir, String fileName) {
    try { _addSignatureToSheet(wb.worksheets[0], wb); } catch (e) { _logger.w(' Erreur signature: $e'); }
    final List<int> bytes = wb.saveAsStream();
    final String filePath = p.join(dir.path, fileName);
    File(filePath).writeAsBytesSync(bytes);
    wb.dispose();
    _logger.i(' Fichier sauvegardé: $filePath');
    return filePath;
  }

  void _addSignatureToSheet(Worksheet sheet, Workbook wb) {
    int signatureRow = sheet.getLastRow() + 2;
    final Style signatureStyle = wb.styles.add('sig_${DateTime.now().millisecondsSinceEpoch}');
    signatureStyle.fontSize = 9; signatureStyle.fontColor = '#808080'; signatureStyle.italic = true;
    final signatureCell = sheet.getRangeByIndex(signatureRow, 1);
    signatureCell.setText('Données générées via Planificator v2.1.1');
    signatureCell.cellStyle = signatureStyle;
  }

  Future<String> genererExcelGenerique({required String title, required List<String> headers, required List<List<dynamic>> data, required String fileName}) async {
    final Workbook workbook = Workbook();
    final Worksheet sheet = workbook.worksheets[0];
    final Style headerStyle = workbook.styles.add('headerStyle');
    headerStyle.bold = true; headerStyle.fontSize = 12; headerStyle.hAlign = HAlignType.center; headerStyle.backColor = '#4472C4'; headerStyle.fontColor = '#FFFFFF';

    int currentRow = 1;
    sheet.getRangeByIndex(currentRow, 1, currentRow, headers.length).merge();
    sheet.getRangeByIndex(currentRow, 1).setText(title);
    sheet.getRangeByIndex(currentRow, 1).cellStyle = headerStyle;
    currentRow += 2;

    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.getRangeByIndex(currentRow, i + 1);
      cell.setText(headers[i]);
      cell.cellStyle = headerStyle;
      cell.cellStyle.borders.all.lineStyle = LineStyle.thin;
    }
    currentRow++;

    for (var row in data) {
      for (int i = 0; i < row.length; i++) {
        final cell = sheet.getRangeByIndex(currentRow, i + 1);
        cell.setValue(row[i]);
        cell.cellStyle.borders.all.lineStyle = LineStyle.thin;
      }
      currentRow++;
    }

    final bytes = workbook.saveAsStream();
    workbook.dispose();
    final paths = await _getPaths();
    final finalPath = p.join(paths[2].path, '$fileName.xlsx');
    await File(finalPath).writeAsBytes(bytes);
    return finalPath;
  }
}
