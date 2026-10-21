import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum VerdictButtonKind { guilty, notGuilty }

/// The two-color verdict buttons used on the voting/verdict screen —
/// mint for "not guilty", peach for "guilty".
class VerdictButton extends StatelessWidget {
  final VerdictButtonKind kind;
  final String label;
  final VoidCallback onPressed;

  const VerdictButton({
    super.key,
    required this.kind,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isGuilty = kind == VerdictButtonKind.guilty;
    final bg = isGuilty ? AppColors.guiltyBg : AppColors.notGuiltyBg;
    final fg = isGuilty ? AppColors.guiltyText : AppColors.notGuiltyText;

    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }
}
