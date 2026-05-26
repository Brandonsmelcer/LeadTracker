import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../services/import_service.dart';
import '../theme/app_theme.dart';

class CsvImportScreen extends StatefulWidget {
  const CsvImportScreen({super.key});

  @override
  State<CsvImportScreen> createState() => _CsvImportScreenState();
}

class _CsvImportScreenState extends State<CsvImportScreen> {
  final _csvCtrl = TextEditingController();

  // Pipeline stages
  List<List<dynamic>>? _parsedRows;
  List<String>? _headers;
  Map<String, String> _columnMapping = {};
  ImportResult? _result;
  bool _isImporting = false;
  int _stage = 0; // 0=paste, 1=map columns, 2=preview, 3=results

  @override
  void dispose() {
    _csvCtrl.dispose();
    super.dispose();
  }

  void _parseFile() {
    final text = _csvCtrl.text.trim();
    if (text.isEmpty) return;

    final rows = ImportService.parseCsv(text);
    if (rows.isEmpty) return;

    final headers = ImportService.extractHeaders(rows);
    final autoMap = ImportService.autoMapColumns(headers);

    setState(() {
      _parsedRows = rows;
      _headers = headers;
      _columnMapping = autoMap;
      _stage = 1;
    });
  }

  Future<void> _runImport() async {
    if (_parsedRows == null) return;
    final provider = context.read<AppProvider>();

    setState(() {
      _isImporting = true;
      _stage = 3;
    });

    final result = ImportService.processRows(
      rows: _parsedRows!,
      columnMapping: _columnMapping,
      existingLeads: provider.leads,
    );

    final leads = ImportService.extractLeads(
      rows: _parsedRows!,
      columnMapping: _columnMapping,
      existingLeads: provider.leads,
    );

    if (leads.isNotEmpty) {
      await provider.addLeads(leads);
    }

    setState(() {
      _result = result;
      _isImporting = false;
    });
  }

  void _reset() {
    setState(() {
      _csvCtrl.clear();
      _parsedRows = null;
      _headers = null;
      _columnMapping = {};
      _result = null;
      _stage = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Leads'),
        actions: [
          if (_stage > 0)
            TextButton(
              onPressed: _reset,
              child: const Text('Start Over',
                  style: TextStyle(color: AppColors.gold)),
            ),
        ],
      ),
      body: _buildStage(),
    );
  }

  Widget _buildStage() {
    switch (_stage) {
      case 0:
        return _buildPasteStage();
      case 1:
        return _buildMappingStage();
      case 2:
        return _buildPreviewStage();
      case 3:
        return _buildResultsStage();
      default:
        return _buildPasteStage();
    }
  }

  // Stage 0: Paste CSV
  Widget _buildPasteStage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFormatGuide(),
          const SizedBox(height: 16),
          const Text('PASTE YOUR LEADS',
              style: TextStyle(color: AppColors.gold, fontSize: 13,
                  letterSpacing: 2, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _csvCtrl,
            maxLines: 14,
            decoration: InputDecoration(
              hintText:
                  'FirstName,LastName,Address,City,State,ZIP,Phone,Email\n'
                  'John,Smith,123 Main St,Nashville,TN,37201,615-555-1234,john@email.com',
              hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            style: const TextStyle(
                color: Colors.white, fontFamily: 'monospace', fontSize: 12),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _parseFile,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Parse & Map Columns'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF00CEC8),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildClearAllButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormatGuide() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.countyBorder.withAlpha(80)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.info_outline, color: AppColors.gold, size: 20),
            SizedBox(width: 8),
            Text('HOW IT WORKS', style: TextStyle(color: AppColors.gold,
                fontSize: 13, letterSpacing: 2, fontWeight: FontWeight.bold)),
          ]),
          SizedBox(height: 8),
          Text(
            'Copy and paste lead data straight from your vendor file. '
            'Column names don\'t need to match exactly — the system '
            'figures out which column is which.\n\n'
            'You don\'t need a county column. County gets filled in '
            'from the ZIP code.\n\n'
            'Duplicates are skipped automatically.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  // Stage 1: Column Mapping
  Widget _buildMappingStage() {
    final matched = _columnMapping.keys
        .where((k) => ImportService.requiredFields.contains(k))
        .length;
    final total = ImportService.requiredFields.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: matched == total
                  ? const Color(0xFF00CEC8).withAlpha(30)
                  : AppColors.accent.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: matched == total
                      ? const Color(0xFF00CEC8)
                      : AppColors.accent),
            ),
            child: Row(
              children: [
                Icon(matched == total ? Icons.check_circle : Icons.warning,
                    color: matched == total
                        ? const Color(0xFF00CEC8) : AppColors.accent),
                const SizedBox(width: 8),
                Text('$matched/$total required fields mapped',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('COLUMN MAPPING', style: TextStyle(color: AppColors.gold,
              fontSize: 13, letterSpacing: 2, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Match your columns to the right fields. Most should be filled in already.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          ...ImportService.allFields.map((field) => _buildMappingRow(field)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _stage = 0),
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.countyBorder)),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: matched == total
                      ? () => setState(() => _stage = 2)
                      : null,
                  icon: const Icon(Icons.preview),
                  label: const Text('Preview Data'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF00CEC8),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMappingRow(String systemField) {
    final isRequired = ImportService.requiredFields.contains(systemField);
    final mapped = _columnMapping[systemField];
    final label = systemField.replaceAll('_', ' ');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: mapped != null
              ? const Color(0xFF00CEC8).withAlpha(80)
              : (isRequired ? AppColors.accent.withAlpha(80) : AppColors.countyBorder.withAlpha(40)),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Row(
              children: [
                if (isRequired)
                  const Text('* ', style: TextStyle(color: AppColors.accent)),
                Flexible(
                  child: Text(label, style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: mapped,
              dropdownColor: AppColors.surface,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                isDense: true,
                border: InputBorder.none,
              ),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              items: [
                const DropdownMenuItem(value: null,
                    child: Text('-- skip --',
                        style: TextStyle(color: AppColors.textSecondary))),
                ...(_headers ?? []).map((h) => DropdownMenuItem(
                    value: h, child: Text(h))),
              ],
              onChanged: (v) {
                setState(() {
                  if (v == null) {
                    _columnMapping.remove(systemField);
                  } else {
                    _columnMapping[systemField] = v;
                  }
                });
              },
            ),
          ),
          if (mapped != null)
            const Icon(Icons.check_circle, size: 16, color: Color(0xFF00CEC8)),
        ],
      ),
    );
  }

  // Stage 2: Preview
  Widget _buildPreviewStage() {
    final previewRows = _parsedRows!.take(11).toList();
    final headers = previewRows.first.map((h) => h.toString()).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${_parsedRows!.length - 1} ROWS TO IMPORT',
              style: const TextStyle(color: AppColors.gold, fontSize: 13,
                  letterSpacing: 2, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Preview of first 10 rows:',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppColors.surface),
              dataRowColor: WidgetStateProperty.all(AppColors.cardDark),
              columnSpacing: 16,
              columns: headers
                  .map((h) => DataColumn(
                      label: Text(h, style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 11))))
                  .toList(),
              rows: previewRows.skip(1).map((row) => DataRow(
                    cells: row
                        .map((cell) => DataCell(Text(
                            cell.toString(),
                            style: const TextStyle(fontSize: 11),
                            overflow: TextOverflow.ellipsis)))
                        .toList(),
                  )).toList(),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _stage = 1),
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.countyBorder)),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _runImport,
                  icon: const Icon(Icons.cloud_upload),
                  label: Text('Import ${_parsedRows!.length - 1} Leads'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF00CEC8),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Stage 3: Results
  Widget _buildResultsStage() {
    if (_isImporting) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF00CEC8)),
            SizedBox(height: 16),
            Text('Importing...', style: TextStyle(fontSize: 16)),
            Text('This should only take a moment.',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    final r = _result!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.cardDark, const Color(0xFF00CEC8).withAlpha(20)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF00CEC8).withAlpha(80)),
            ),
            child: Column(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF00CEC8), size: 48),
                const SizedBox(height: 8),
                const Text('IMPORT COMPLETE', style: TextStyle(
                    color: Color(0xFF00CEC8), fontSize: 16,
                    letterSpacing: 2, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _resultStat('Total', '${r.total}', AppColors.textPrimary),
                    _resultStat('Imported', '${r.imported}', const Color(0xFF00CEC8)),
                    _resultStat('Dupes', '${r.duplicates}', AppColors.warning),
                    _resultStat('Errors', '${r.errors}', AppColors.accent),
                  ],
                ),
              ],
            ),
          ),
          if (r.countyTotals.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('COUNTY BREAKDOWN', style: TextStyle(color: AppColors.gold,
                fontSize: 13, letterSpacing: 2, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...r.countyTotals.entries.map((e) {
              final parts = e.key.split('_');
              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(4)),
                      child: Text(parts[0], style: const TextStyle(
                          color: AppColors.gold, fontSize: 11)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(parts.length > 1 ? parts[1] : e.key)),
                    Text('${e.value} leads',
                        style: const TextStyle(
                            color: Color(0xFF00CEC8), fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }),
          ],
          if (r.errorMessages.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('ERRORS', style: TextStyle(color: AppColors.accent,
                fontSize: 13, letterSpacing: 2, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accent.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: r.errorMessages.take(20).map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(e, style: const TextStyle(
                          color: AppColors.accent, fontSize: 12)),
                    )).toList(),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.add),
                  label: const Text('Import More'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF00CEC8),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.dashboard),
                  label: const Text('Go to Dashboard'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.gold),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _resultStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(
            fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(
            fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildClearAllButton() {
    return OutlinedButton.icon(
      onPressed: () => _confirmClearAll(),
      icon: const Icon(Icons.delete_sweep, color: AppColors.accent, size: 18),
      label: const Text('Clear All Leads',
          style: TextStyle(color: AppColors.accent, fontSize: 12)),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.accent),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      ),
    );
  }

  void _confirmClearAll() {
    final provider = context.read<AppProvider>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text('Clear All Leads'),
        content: Text(
            'This will permanently delete all ${provider.leads.length} leads '
            'and reset all county totals to zero.\n\n'
            'This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await provider.clearAllLeads();
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All leads cleared'),
                    backgroundColor: AppColors.surface,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
            child: const Text('Clear Everything'),
          ),
        ],
      ),
    );
  }
}
