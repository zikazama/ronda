import 'package:flutter/material.dart';

/// Palet warna RONDA — biru siber yang bersih dengan aksen risiko.
abstract final class AppColors {
  // Brand
  static const primary = Color(0xFF1677F2);
  static const primaryDark = Color(0xFF0B4FC4);
  static const primarySoft = Color(0xFFE8F1FE);

  // Surface
  static const background = Color(0xFFF5F8FD);
  static const surface = Colors.white;
  static const outline = Color(0xFFE3EAF4);

  // Text
  static const textPrimary = Color(0xFF0F1B2D);
  static const textSecondary = Color(0xFF5B6B82);
  static const textMuted = Color(0xFF93A0B4);

  // Risk
  static const safe = Color(0xFF1FA55B);
  static const safeSoft = Color(0xFFE6F6EE);
  static const warning = Color(0xFFF59E0B);
  static const warningSoft = Color(0xFFFEF3DC);
  static const danger = Color(0xFFE5484D);
  static const dangerSoft = Color(0xFFFDECEC);
}
