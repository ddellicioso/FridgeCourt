import 'package:flutter/material.dart';
import '../data/case_store.dart';
import '../theme/app_colors.dart';

class ReportScreen extends StatefulWidget {
  final CaseStore store;

  const ReportScreen({super.key, required this.store});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _crimeController = TextEditingController();
  final _accusedController = TextEditingController();
  final _evidenceController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _crimeController.dispose();
    _accusedController.dispose();
    _evidenceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      await widget.store.addCase(
        crimeTitle: _crimeController.text.trim(),
        accused: _accusedController.text.trim(),
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'What happened?',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _crimeController,
              decoration: const InputDecoration(
                hintText: 'e.g. Theft of the last dumpling',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Describe the crime' : null,
            ),
            const SizedBox(height: 18),
            const Text(
              'Who did it?',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _accusedController,
              decoration: const InputDecoration(hintText: 'Housemate name'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name the accused' : null,
            ),
            const SizedBox(height: 18),
            const Text(
              'Evidence',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _evidenceController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Describe what you saw (photo upload coming later)',
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.quoteAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Submit to the Court',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}