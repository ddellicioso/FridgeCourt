import 'package:flutter/material.dart';
import '../data/case_store.dart';
import '../data/crime_menu.dart';
import '../models/case.dart';
import '../theme/app_colors.dart';

/// Filing a crime is: pick who did it (1 tap), pick the crime from the
/// menu (1 tap) — that second tap files the case immediately. An
/// optional evidence note can be typed first, but nothing requires it,
/// so filing a report never needs more than 2 taps.
class ReportScreen extends StatefulWidget {
  final CaseStore store;

  const ReportScreen({super.key, required this.store});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _evidenceController = TextEditingController();
  String? _selectedAccused;
  bool _submitting = false;

  @override
  void dispose() {
    _evidenceController.dispose();
    super.dispose();
  }

  List<String> get _accusable => widget.store.householdMembers
      .where((m) => m.toLowerCase() != widget.store.displayName.toLowerCase())
      .toList();

  Future<void> _fileCase(CrimeDef crime) async {
    if (_selectedAccused == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick who did it first.')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await widget.store.addCase(
        accused: _selectedAccused!,
        crime: crime,
        evidenceNote: _evidenceController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Case filed. The jury has been summoned.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not file the case: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('File a Crime')),
      body: AbsorbPointer(
        absorbing: _submitting,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            const Text(
              '1. Who did it?',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _accusable.map((name) {
                final selected = _selectedAccused == name;
                return ChoiceChip(
                  label: Text(name),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedAccused = name),
                  selectedColor: AppColors.quoteAccent,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: AppColors.cardBorder),
                );
              }).toList(),
            ),
            const SizedBox(height: 22),
            const Text(
              'Evidence (optional)',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _evidenceController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Describe what you saw (photo upload coming later)',
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              '2. What did they do? (tap to file)',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 10),
            for (final severity in Severity.values) ...[
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 6),
                child: Text(
                  severity.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.quoteAccent,
                    fontSize: 12.5,
                  ),
                ),
              ),
              ...crimesOfSeverity(severity).map(
                (crime) => Card(
                  child: ListTile(
                    title: Text(crime.title),
                    trailing: const Icon(Icons.gavel, size: 18),
                    onTap: _submitting ? null : () => _fileCase(crime),
                  ),
                ),
              ),
            ],
            if (_submitting) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }
}
