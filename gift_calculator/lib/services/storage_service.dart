import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/gift_entry.dart';

/// Everything the app persists for one event: no server, no login — the
/// ledger lives on this device only, exported by hand when the couple wants
/// a copy elsewhere.
class LedgerData {
  String ownerName;
  int ticketTotal;
  int nextNo;
  List<GiftEntry> entries;

  LedgerData({
    required this.ownerName,
    required this.ticketTotal,
    required this.nextNo,
    required this.entries,
  });

  factory LedgerData.empty() => LedgerData(
        ownerName: '',
        ticketTotal: 0,
        nextNo: 1,
        entries: [],
      );
}

class StorageService {
  static const _key = 'gift_calculator_ledger_v1';

  Future<LedgerData> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return LedgerData.empty();
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return LedgerData(
        ownerName: data['ownerName'] as String? ?? '',
        ticketTotal: data['ticketTotal'] as int? ?? 0,
        nextNo: data['nextNo'] as int? ?? 1,
        entries: ((data['entries'] as List<dynamic>?) ?? [])
            .map((e) => GiftEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } catch (_) {
      // Corrupt or from an incompatible older version: start fresh rather
      // than crash the reception desk mid-event.
      return LedgerData.empty();
    }
  }

  Future<void> save(LedgerData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode({
        'ownerName': data.ownerName,
        'ticketTotal': data.ticketTotal,
        'nextNo': data.nextNo,
        'entries': data.entries.map((e) => e.toJson()).toList(),
      }),
    );
  }
}
