import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../storage/prefs.dart';
import 'bloom_filter.dart';

/// Lapis 1 — daftar ancaman lokal yang bekerja tanpa internet.
///
/// - **Blocklist**: nomor yang ditandai pengguna sendiri (pasti, tanpa false positive).
/// - **Bloom filter**: nomor paling sering dilaporkan komunitas, disinkronkan
///   dari Firestore (hemat memori; false positive ~0,1%).
class ThreatListStore {
  ThreatListStore(this._prefs) {
    final encoded = _prefs.getString(_bloomKey);
    if (encoded != null) {
      try {
        _bloom = BloomFilter.fromBase64(encoded);
      } on Object {
        _bloom = null; // data rusak: abaikan, akan dibangun ulang saat sinkron
      }
    }
  }

  static const _blocklistKey = 'threat.blocklist';
  static const _bloomKey = 'threat.bloom';
  static const _syncedAtKey = 'threat.syncedAt';
  static const bloomCapacity = 10000;

  final SharedPreferences _prefs;
  BloomFilter? _bloom;

  Set<String> get blocklist =>
      (_prefs.getStringList(_blocklistKey) ?? const []).toSet();

  bool isBlocked(String key) => blocklist.contains(key);

  bool isKnownSpam(String key) =>
      isBlocked(key) || (_bloom?.mightContain(key) ?? false);

  Future<void> block(String key) async {
    final list = blocklist..add(key);
    await _prefs.setStringList(_blocklistKey, list.toList());
  }

  /// Membangun ulang Bloom Filter dari [keys] hasil sinkronisasi.
  Future<void> replaceCommunityList(Iterable<String> keys) async {
    final list = keys.toList();
    final bloom = BloomFilter.forCapacity(
      list.length > bloomCapacity ? list.length : bloomCapacity,
      falsePositiveRate: 0.001, // 0,1%: pesan wajar jangan sampai terblokir
    );
    for (final k in list) {
      bloom.add(k);
    }
    _bloom = bloom;
    await _prefs.setString(_bloomKey, bloom.toBase64());
    await _prefs.setInt(_syncedAtKey, DateTime.now().millisecondsSinceEpoch);
  }

  DateTime? get lastSyncedAt {
    final ms = _prefs.getInt(_syncedAtKey);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  bool get needsSync {
    final last = lastSyncedAt;
    return last == null ||
        DateTime.now().difference(last) > const Duration(hours: 6);
  }
}

final threatListStoreProvider = Provider<ThreatListStore>(
  (ref) => ThreatListStore(ref.watch(sharedPreferencesProvider)),
);
