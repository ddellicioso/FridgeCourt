import 'package:flutter/material.dart';
import '../models/case.dart';
import '../theme/app_colors.dart';
import 'status_pill.dart';

class CaseCard extends StatelessWidget {
  final FridgeCase fridgeCase;
  final VoidCallback onTap;

  /// Whether this card should show a "needs your attention" tag — passed
  /// in by the caller, which already knows the current person's uid and
  /// display name (CaseStore.pendingForMe).
  final bool needsMyAttention;
  final String? attentionReason;

  const CaseCard({
    super.key,
    required this.fridgeCase,
    required this.onTap,
    this.needsMyAttention = false,
    this.attentionReason,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      fridgeCase.crimeTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  StatusPill(status: fridgeCase.status),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Accused: ${fridgeCase.accused}  ·  Filed by ${fridgeCase.reporter}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${fridgeCase.severity.label} severity',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (fridgeCase.status == CaseStatus.onTrial) ...[
                const SizedBox(height: 8),
                Text(
                  '${fridgeCase.guiltyVotes} guilty · ${fridgeCase.notGuiltyVotes} not guilty',
                  style: const TextStyle(
                    color: AppColors.quoteAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (needsMyAttention) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.guilty.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    attentionReason ?? 'Needs your attention',
                    style: const TextStyle(
                      color: AppColors.guilty,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
