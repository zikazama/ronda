import '../../features/scan/domain/scan_result.dart';

/// Kode jenis ancaman (sesuai field `threat_type` pada kontrak API).
abstract final class ThreatCodes {
  static const none = 'NONE';
  static const apkScam = 'APK_SCAM';
  static const financialPhishing = 'FINANCIAL_PHISHING';
  static const impersonation = 'IMPERSONATION';
  static const suspiciousLink = 'SUSPICIOUS_LINK';
  static const socialEngineering = 'SOCIAL_ENGINEERING';
  static const knownScammer = 'KNOWN_SCAMMER';
}

class RuleResult {
  const RuleResult({
    required this.score,
    required this.threatCode,
    required this.entities,
    required this.signals,
  });

  /// Skor risiko 0..1.
  final double score;
  final String threatCode;
  final ExtractedEntities entities;

  /// Alasan yang terpicu (untuk ringkasan & debugging).
  final List<String> signals;

  static const clean = RuleResult(
    score: 0,
    threatCode: ThreatCodes.none,
    entities: ExtractedEntities(),
    signals: [],
  );
}

class _Signal {
  const _Signal(this.name, this.weight, this.threat);
  final String name;
  final double weight;
  final String threat;
}

/// Lapis 3 — Rule Engine: regex & parser finansial yang berjalan lokal.
class RuleEngine {
  const RuleEngine();

  /// Skor di atas ini dianggap pasti berbahaya tanpa perlu AI.
  static const highThreshold = 0.85;

  /// Skor di bawah ini dianggap aman tanpa perlu AI.
  static const lowThreshold = 0.30;

  static final _apk = RegExp(r'\.x?apks?\b|\bapk\b', caseSensitive: false);
  static final _url = RegExp(
    r'(?:https?:\/\/|www\.)[^\s<>"]+|\b[a-z0-9\-]+(?:\.[a-z0-9\-]+)*\.(?:com|id|co\.id|net|org|xyz|top|click|vip|icu|cc|ly|gl|link|site|online|shop|info|me|s\.id)\b(?:\/[^\s]*)?',
    caseSensitive: false,
  );
  static const _shorteners = [
    'bit.ly', 'tinyurl.com', 's.id', 't.ly', 'cutt.ly', 'shorturl.at',
    'rb.gy', 'is.gd', 'goo.gl', 'ow.ly', 'bitly.com', 't.me', 'wa.me', //
  ];
  static const _riskyTlds = [
    '.xyz',
    '.top',
    '.click',
    '.vip',
    '.icu',
    '.cc',
    '.link',
    '.site',
  ];
  static const _brands = {
    'bca': ['bca.co.id'],
    'bri': ['bri.co.id'],
    'bni': ['bni.co.id'],
    'mandiri': ['bankmandiri.co.id'],
    'dana': ['dana.id'],
    'ovo': ['ovo.id'],
    'gopay': ['gopay.co.id', 'gojek.com'],
    'shopee': ['shopee.co.id'],
    'tokopedia': ['tokopedia.com'],
    'bpjs': ['bpjs-kesehatan.go.id', 'bpjsketenagakerjaan.go.id'],
    'pajak': ['pajak.go.id'],
    'polri': ['polri.go.id'],
  };
  static final _account = RegExp(
    r'(?:rek(?:ening)?|no\.?\s*rek|norek|a\/?n\.?|atas\s+nama|transfer(?:\s+ke)?|tf(?:\s+ke)?|trf)\D{0,14}(\d{8,16})|(?:bca|bri|bni|mandiri|btn|cimb|permata|danamon|bsi|jago|seabank|dana|ovo|gopay)\D{0,10}(\d{8,16})',
    caseSensitive: false,
  );

  // (pola, sinyal) — bobot per kategori; digabung dengan noisy-OR.
  static final _keywordSignals = <RegExp, _Signal>{
    RegExp(
      r'\b(tilang|etle|surat\s+panggilan|polisi|kejaksaan|pengadilan|satpol)\b',
      caseSensitive: false,
    ): const _Signal(
      'otoritas palsu',
      0.45,
      ThreatCodes.impersonation,
    ),
    RegExp(r'\b(bpjs|pajak|djp|bea\s*cukai|kemenkes)\b', caseSensitive: false):
        const _Signal('instansi', 0.2, ThreatCodes.impersonation),
    RegExp(
      r'\b(diblokir|akan\s+diblokir|dibekukan|ditutup|kadaluarsa|suspend)\b',
      caseSensitive: false,
    ): const _Signal(
      'ancaman blokir',
      0.35,
      ThreatCodes.financialPhishing,
    ),
    RegExp(
      r'\b(otp|kode\s+verifikasi|kode\s+rahasia|pin\s+(anda|atm)|cvv|password|kata\s+sandi)\b',
      caseSensitive: false,
    ): const _Signal(
      'minta data rahasia',
      0.5,
      ThreatCodes.financialPhishing,
    ),
    RegExp(
      r'\b(hadiah|pemenang|undian|selamat\s+anda|menang|klaim|giveaway)\b',
      caseSensitive: false,
    ): const _Signal(
      'iming-iming hadiah',
      0.4,
      ThreatCodes.socialEngineering,
    ),
    RegExp(
      r'\b(lowongan|kerja\s+online|part\s*time|komisi|tugas\s+like|freelance\s+online)\b',
      caseSensitive: false,
    ): const _Signal(
      'tawaran kerja',
      0.35,
      ThreatCodes.socialEngineering,
    ),
    RegExp(
      r'\b(investasi|profit|cuan|deposit|depo|wd|withdraw|modal\s+kecil|trading)\b',
      caseSensitive: false,
    ): const _Signal(
      'investasi cepat untung',
      0.3,
      ThreatCodes.financialPhishing,
    ),
    RegExp(
      r'\b(pinjol|pinjaman\s+(cair|online|dana)|dana\s+cair)\b',
      caseSensitive: false,
    ): const _Signal(
      'pinjaman',
      0.35,
      ThreatCodes.financialPhishing,
    ),
    RegExp(
      r'\b(resi|kurir|paket)\b.{0,40}\b(gagal|tidak\s+dapat|tertahan|alamat|konfirmasi)\b',
      caseSensitive: false,
    ): const _Signal(
      'paket palsu',
      0.5,
      ThreatCodes.apkScam,
    ),
    RegExp(
      r'\b(undangan)\s+(pernikahan|nikah|digital|wedding)\b',
      caseSensitive: false,
    ): const _Signal(
      'undangan palsu',
      0.5,
      ThreatCodes.apkScam,
    ),
    RegExp(
      r'\b(mama|papa|ayah|ibu|bunda)\s+(minta|butuh)\s+(pulsa|transfer|uang)\b',
      caseSensitive: false,
    ): const _Signal(
      'penyamaran keluarga',
      0.55,
      ThreatCodes.impersonation,
    ),
    RegExp(
      r'\b(segera|sekarang\s+juga|batas\s+waktu|terakhir|darurat|urgent|penting)\b',
      caseSensitive: false,
    ): const _Signal(
      'desakan waktu',
      0.15,
      ThreatCodes.socialEngineering,
    ),
    RegExp(
      r'\b(unduh|download|instal|install|buka\s+(file|lampiran|paket))\b',
      caseSensitive: false,
    ): const _Signal(
      'minta unduh',
      0.2,
      ThreatCodes.apkScam,
    ),
    RegExp(r'\bqris\b', caseSensitive: false): const _Signal(
      'QRIS',
      0.15,
      ThreatCodes.financialPhishing,
    ),
  };

  RuleResult analyze(String body) {
    if (body.trim().isEmpty) return RuleResult.clean;

    final signals = <_Signal>[];
    String? fileExtension;
    String? bankAccount;
    String? suspiciousUrl;

    // File berbahaya (.apk)
    final apk = _apk.firstMatch(body);
    if (apk != null) {
      fileExtension = '.apk';
      signals.add(const _Signal('file APK', 0.9, ThreatCodes.apkScam));
    }

    // Tautan
    for (final m in _url.allMatches(body)) {
      final url = m.group(0)!;
      final host = _hostOf(url);
      if (_shorteners.any((s) => host == s || host.endsWith('.$s'))) {
        suspiciousUrl ??= url;
        signals.add(
          const _Signal('link pendek', 0.45, ThreatCodes.suspiciousLink),
        );
      } else if (_riskyTlds.any(host.endsWith)) {
        suspiciousUrl ??= url;
        signals.add(
          const _Signal('domain berisiko', 0.4, ThreatCodes.suspiciousLink),
        );
      } else if (RegExp(r'^\d{1,3}(\.\d{1,3}){3}$').hasMatch(host)) {
        suspiciousUrl ??= url;
        signals.add(
          const _Signal('URL alamat IP', 0.5, ThreatCodes.suspiciousLink),
        );
      }
      for (final brand in _brands.entries) {
        if (host.contains(brand.key) &&
            !brand.value.any(
              (official) => host == official || host.endsWith('.$official'),
            )) {
          suspiciousUrl ??= url;
          signals.add(
            _Signal(
              'domain meniru ${brand.key}',
              0.6,
              ThreatCodes.impersonation,
            ),
          );
        }
      }
    }

    // Nomor rekening
    final acc = _account.firstMatch(body);
    if (acc != null) {
      bankAccount = acc.group(1) ?? acc.group(2);
      signals.add(
        const _Signal('nomor rekening', 0.35, ThreatCodes.financialPhishing),
      );
    }

    // Kata kunci manipulasi
    for (final entry in _keywordSignals.entries) {
      if (entry.key.hasMatch(body)) signals.add(entry.value);
    }

    if (signals.isEmpty) return RuleResult.clean;

    // Noisy-OR: tiap sinyal independen menaikkan keyakinan.
    var inverse = 1.0;
    for (final s in signals) {
      inverse *= 1 - s.weight;
    }
    final score = 1 - inverse;

    // Jenis ancaman = sinyal berbobot tertinggi.
    final top = signals.reduce((a, b) => a.weight >= b.weight ? a : b);

    return RuleResult(
      score: score,
      threatCode: top.threat,
      entities: ExtractedEntities(
        bankAccount: bankAccount,
        fileExtension: fileExtension,
        suspiciousUrl: suspiciousUrl,
      ),
      signals: signals.map((e) => e.name).toSet().toList(growable: false),
    );
  }

  static String _hostOf(String url) {
    var s = url.toLowerCase().replaceFirst(RegExp(r'^https?:\/\/'), '');
    s = s.replaceFirst(RegExp(r'^www\.'), '');
    return s.split(RegExp(r'[/?#:]')).first;
  }
}
