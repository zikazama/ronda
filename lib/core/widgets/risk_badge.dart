import 'package:flutter/material.dart';

import '../../features/scan/domain/scan_result.dart';

class RiskBadge extends StatelessWidget {
  const RiskBadge(this.level, {super.key});

  final RiskLevel level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: level.softColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        level.label,
        style: TextStyle(
          color: level.color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
