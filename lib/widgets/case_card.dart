import 'package:flutter/material.dart';
import '../models/case.dart';
import '../theme/app_colors.dart';
import 'status_pill.dart';

class CaseCard extends StatelessWidget {
  final FridgeCase fridgeCase;
  final VoidCallback onTap;

  const CaseCard({super.key, required this.fridgeCase, required this.onTap});

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
            ],
          ),
        ),
      ),
    );
  }
}
