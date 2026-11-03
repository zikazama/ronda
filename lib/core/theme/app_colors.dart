import 'package:flutter/material.dart';

/// Palet RONDA: biru malam (penjaga yang berjaga) dengan warna risiko yang
/// konsisten di seluruh aplikasi.
abstract final class AppColors {
  // Brand
  static const night = Color(0xFF0D1B34); // panel & teks utama
  static const nightRaised = Color(0xFF16284A); // permukaan di atas panel
  static const primary = Color(0xFF1569E8);
  static const primaryDark = Color(0xFF0B4FC4);
  static const primarySoft = Color(0xFFE8F0FD);

  // Surface
  static const background = Color(0xFFF4F6FA);
  static const surface = Colors.white;
  static const outline = Color(0xFFE1E7F0);

  // Text (kontras ≥ 4,5:1 pada putih & latar)
  static const textPrimary = night;
  static const textSecondary = Color(0xFF45546B);
  static const textMuted = Color(0xFF64748B);

  // Risk
  static const safe = Color(0xFF12915F);
  static const safeSoft = Color(0xFFE3F5EC);
  static const warning = Color(0xFFB87500); // teks/ikon pada latar terang
  static const warningFill = Color(0xFFF5A524); // isian grafik/peta
  static const warningSoft = Color(0xFFFEF1D6);
  static const danger = Color(0xFFD6343B);
  static const dangerSoft = Color(0xFFFCE9EA);

  // Risiko di atas panel gelap
  static const safeOnNight = Color(0xFF4ADE9F);
  static const warningOnNight = Color(0xFFFFC247);
  static const dangerOnNight = Color(0xFFFF7A7F);
}
