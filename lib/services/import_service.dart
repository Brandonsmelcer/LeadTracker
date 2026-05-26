import 'package:csv/csv.dart';
import '../models/models.dart';
import '../data/zip_county_lookup.dart';

class ImportService {
  static const _knownAliases = <String, List<String>>{
    'first_name': ['firstname', 'fname', 'first', 'first_name', 'givenname'],
    'last_name': ['lastname', 'lname', 'last', 'last_name', 'surname', 'familyname'],
    'address': ['address', 'address1', 'street', 'streetaddress', 'addr', 'street_address'],
    'city': ['city', 'town', 'municipality'],
    'state': ['state', 'st', 'statecode', 'state_code', 'province'],
    'zip': ['zip', 'zipcode', 'zip_code', 'postalcode', 'postal_code', 'postal'],
    'phone': ['phone', 'phonenumber', 'phone_number', 'tel', 'telephone', 'mobile', 'cell'],
    'email': ['email', 'emailaddress', 'email_address', 'e_mail'],
    'assignee': ['assignee', 'assigned_to', 'agent', 'rep', 'representative'],
    'source': ['source', 'lead_source', 'leadsource', 'vendor', 'origin'],
    'notes': ['notes', 'note', 'comments', 'comment', 'description'],
  };

  static const requiredFields = ['first_name', 'last_name', 'state', 'zip'];
  static const allFields = [
    'first_name', 'last_name', 'address', 'city', 'state',
    'zip', 'phone', 'email', 'assignee', 'source', 'notes',
  ];

  static List<List<dynamic>> parseCsv(String content) {
    String normalized = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    if (!normalized.endsWith('\n')) normalized += '\n';
    return const CsvToListConverter(eol: '\n', shouldParseNumbers: false)
        .convert(normalized);
  }

  static List<String> extractHeaders(List<List<dynamic>> rows) {
    if (rows.isEmpty) return [];
    return rows.first.map((h) => h.toString().trim()).toList();
  }

  static Map<String, String> autoMapColumns(List<String> headers) {
    final mapping = <String, String>{};
    for (final field in allFields) {
      final aliases = _knownAliases[field] ?? [field];
      for (final header in headers) {
        final normalized = header.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
        for (final alias in aliases) {
          if (normalized == alias.replaceAll('_', '')) {
            mapping[field] = header;
            break;
          }
        }
        if (mapping.containsKey(field)) break;
      }
    }
    return mapping;
  }

  static ImportResult processRows({
    required List<List<dynamic>> rows,
    required Map<String, String> columnMapping,
    required List<Lead> existingLeads,
  }) {
    if (rows.length < 2) {
      return const ImportResult(errorMessages: ['File has no data rows']);
    }

    final headers = rows.first.map((h) => h.toString().trim()).toList();
    final leads = <Lead>[];
    final errors = <String>[];
    int duplicates = 0;

    final existingKeys = <String>{};
    for (final lead in existingLeads) {
      existingKeys.add(_dedupeKey(lead));
    }

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.every((cell) => cell.toString().trim().isEmpty)) continue;

      try {
        final values = <String, String>{};
        for (final entry in columnMapping.entries) {
          final headerIdx = headers.indexOf(entry.value);
          if (headerIdx >= 0 && headerIdx < row.length) {
            values[entry.key] = row[headerIdx].toString().trim();
          }
        }

        final firstName = values['first_name'] ?? '';
        final lastName = values['last_name'] ?? '';
        final zip = _normalizeZip(values['zip'] ?? '');
        final state = _normalizeState(values['state'] ?? '');

        if (firstName.isEmpty && lastName.isEmpty) {
          errors.add('Row ${i + 1}: Missing name');
          continue;
        }
        if (zip.isEmpty && state.isEmpty) {
          errors.add('Row ${i + 1}: Missing ZIP and state');
          continue;
        }

        String county = '';
        String resolvedState = state;
        if (zip.isNotEmpty) {
          final lookup = ZipCountyLookup.lookup(zip);
          if (lookup != null) {
            county = lookup[0];
            if (resolvedState.isEmpty) resolvedState = lookup[1];
          }
        }

        if (!_isTargetState(resolvedState)) {
          errors.add('Row ${i + 1}: State $resolvedState not in TN/KY/WV');
          continue;
        }

        final lead = Lead(
          firstName: _titleCase(firstName),
          lastName: _titleCase(lastName),
          address: values['address'] ?? '',
          city: _titleCase(values['city'] ?? ''),
          state: resolvedState.toUpperCase(),
          zip: zip,
          county: county,
          phone: _normalizePhone(values['phone'] ?? ''),
          email: (values['email'] ?? '').toLowerCase(),
          assignee: values['assignee'],
          source: values['source'],
          notes: values['notes'],
        );

        final key = _dedupeKey(lead);
        if (existingKeys.contains(key)) {
          duplicates++;
          continue;
        }
        existingKeys.add(key);
        leads.add(lead);
      } catch (e) {
        errors.add('Row ${i + 1}: $e');
      }
    }

    final countyTotals = <String, int>{};
    for (final lead in leads) {
      if (lead.county.isNotEmpty) {
        final key = '${lead.state}_${lead.county}';
        countyTotals[key] = (countyTotals[key] ?? 0) + 1;
      }
    }

    return ImportResult(
      total: rows.length - 1,
      imported: leads.length,
      duplicates: duplicates,
      errors: errors.length,
      errorMessages: errors,
      countyTotals: countyTotals,
    );
  }

  static List<Lead> extractLeads({
    required List<List<dynamic>> rows,
    required Map<String, String> columnMapping,
    required List<Lead> existingLeads,
  }) {
    if (rows.length < 2) return [];

    final headers = rows.first.map((h) => h.toString().trim()).toList();
    final leads = <Lead>[];
    final existingKeys = <String>{};
    for (final lead in existingLeads) {
      existingKeys.add(_dedupeKey(lead));
    }

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.every((cell) => cell.toString().trim().isEmpty)) continue;

      try {
        final values = <String, String>{};
        for (final entry in columnMapping.entries) {
          final headerIdx = headers.indexOf(entry.value);
          if (headerIdx >= 0 && headerIdx < row.length) {
            values[entry.key] = row[headerIdx].toString().trim();
          }
        }

        final firstName = values['first_name'] ?? '';
        final lastName = values['last_name'] ?? '';
        final zip = _normalizeZip(values['zip'] ?? '');
        final state = _normalizeState(values['state'] ?? '');

        if (firstName.isEmpty && lastName.isEmpty) continue;
        if (zip.isEmpty && state.isEmpty) continue;

        String county = '';
        String resolvedState = state;
        if (zip.isNotEmpty) {
          final lookup = ZipCountyLookup.lookup(zip);
          if (lookup != null) {
            county = lookup[0];
            if (resolvedState.isEmpty) resolvedState = lookup[1];
          }
        }

        if (!_isTargetState(resolvedState)) continue;

        final lead = Lead(
          firstName: _titleCase(firstName),
          lastName: _titleCase(lastName),
          address: values['address'] ?? '',
          city: _titleCase(values['city'] ?? ''),
          state: resolvedState.toUpperCase(),
          zip: zip,
          county: county,
          phone: _normalizePhone(values['phone'] ?? ''),
          email: (values['email'] ?? '').toLowerCase(),
          assignee: values['assignee'],
          source: values['source'],
          notes: values['notes'],
        );

        final key = _dedupeKey(lead);
        if (existingKeys.contains(key)) continue;
        existingKeys.add(key);
        leads.add(lead);
      } catch (_) {}
    }
    return leads;
  }

  static String _dedupeKey(Lead lead) =>
      '${lead.firstName.toLowerCase()}_${lead.lastName.toLowerCase()}_${lead.zip}_${lead.phone}';

  static String _normalizeZip(String zip) {
    final cleaned = zip.replaceAll(RegExp(r'[^0-9-]'), '');
    return cleaned.split('-').first.padLeft(5, '0').substring(0, 5);
  }

  static String _normalizeState(String state) {
    final s = state.trim().toUpperCase();
    const names = {
      'TENNESSEE': 'TN', 'KENTUCKY': 'KY', 'WEST VIRGINIA': 'WV',
    };
    return names[s] ?? s;
  }

  static String _normalizePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 10) {
      return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6)}';
    }
    if (digits.length == 11 && digits.startsWith('1')) {
      return '(${digits.substring(1, 4)}) ${digits.substring(4, 7)}-${digits.substring(7)}';
    }
    return phone;
  }

  static String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s.split(' ').map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');
  }

  static bool _isTargetState(String state) {
    return ['TN', 'KY', 'WV'].contains(state.toUpperCase());
  }
}
