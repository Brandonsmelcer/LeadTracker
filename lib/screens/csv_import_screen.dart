import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class CsvImportScreen extends StatefulWidget {
  const CsvImportScreen({super.key});

  @override
  State<CsvImportScreen> createState() => _CsvImportScreenState();
}

class _CsvImportScreenState extends State<CsvImportScreen> {
  final _csvCtrl = TextEditingController();
  String? _result;

  @override
  void dispose() {
    _csvCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Import CSV')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.countyBorder.withAlpha(80)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.gold, size: 20),
                      SizedBox(width: 8),
                      Text('CSV FORMAT',
                          style: TextStyle(
                              color: AppColors.gold,
                              fontSize: 13,
                              letterSpacing: 2,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your CSV should have these columns:\n'
                    'State Code, County Name, Lead Count, Assignee (optional)\n\n'
                    'Example:\n'
                    'State,County,Leads,Assignee\n'
                    'TN,Davidson,45,Kyle Stallons\n'
                    'KY,Jefferson,30,\n'
                    'WV,Kanawha,15,',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('PASTE CSV DATA',
                style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 13,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _csvCtrl,
              maxLines: 12,
              decoration: InputDecoration(
                hintText: 'State,County,Leads,Assignee\nTN,Davidson,45,',
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              style: const TextStyle(
                  color: Colors.white, fontFamily: 'monospace', fontSize: 13),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  if (_csvCtrl.text.trim().isEmpty) {
                    setState(() => _result = 'Please paste CSV data first');
                    return;
                  }
                  final result = provider.importCsv(_csvCtrl.text);
                  setState(() => _result = result);
                },
                icon: const Icon(Icons.upload_file),
                label: const Text('Import'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            if (_result != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _result!.startsWith('Error')
                      ? AppColors.accent.withAlpha(30)
                      : AppColors.success.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _result!.startsWith('Error')
                        ? AppColors.accent
                        : AppColors.success,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _result!.startsWith('Error')
                          ? Icons.error
                          : Icons.check_circle,
                      color: _result!.startsWith('Error')
                          ? AppColors.accent
                          : AppColors.success,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_result!,
                          style: const TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
