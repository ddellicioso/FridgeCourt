import 'package:flutter/material.dart';
import '../models/case.dart';
import '../theme/app_colors.dart';

class StatusPill extends StatelessWidget {
  final CaseStatus status;

  const StatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      CaseStatus.pending => (AppColors.pending, AppColors.pendingText),
      CaseStatus.onTrial => (
          AppColors.quoteAccent.withOpacity(0.15),
          AppColors.quoteAccent
        ),
      CaseStatus.guilty => (AppColors.guilty, Colors.white),
      CaseStatus.notGuilty => (AppColors.notGuiltyBg, AppColors.notGuiltyText),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
