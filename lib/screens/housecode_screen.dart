import 'dart:math';
import 'package:flutter/material.dart';
import '../data/case_store.dart';
import '../demo_mode.dart';
import '../services/household_service.dart';
import '../theme/app_colors.dart';
import 'home_screen.dart';

/// First screen a device sees if it isn't already part of a household.
/// Two paths: start a new household (get a code to share) or join one
/// with a code someone already shared with you.
class HousecodeScreen extends StatefulWidget {
  const HousecodeScreen({super.key});

  @override
  State<HousecodeScreen> createState() => _HousecodeScreenState();
}

enum _Mode { choose, create, join }

class _HousecodeScreenState extends State<HousecodeScreen> {
  _Mode _mode = _Mode.choose;
  bool _loading = false;
  String? _error;

  // Prefilled so the demo recording doesn't need any typing here — change
  // these if you want, just keep _seedDemoCases() in case_store.dart's
  // accused name lined up with whatever name you use when recording.
  final _nameController = TextEditingController(text: kDemoMode ? 'Maya' : '');
  final _houseNameController =
      TextEditingController(text: kDemoMode ? 'The Loft' : '');
  final _codeController = TextEditingController(text: kDemoMode ? 'DEMO42' : '');

  @override
  void dispose() {
    _nameController.dispose();
    _houseNameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _enterApp(String householdCode, String displayName) {
    final store = kDemoMode
        ? CaseStore.demo(householdCode: householdCode, displayName: displayName)
        : CaseStore(householdCode: householdCode, displayName: displayName);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => HomeScreen(store: store)),
    );
  }

  String _generateDemoCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<void> _create() async {
    if (_nameController.text.trim().isEmpty ||
        _houseNameController.text.trim().isEmpty) {
      setState(() => _error = 'Fill in both fields.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final code = kDemoMode
          ? _generateDemoCode()
          : await HouseholdService.instance.createHousehold(
              houseName: _houseNameController.text.trim(),
              displayName: _nameController.text.trim(),
            );
      if (!mounted) return;
      await _showCodeDialog(code);
      if (!mounted) return;
      _enterApp(code, _nameController.text.trim());
    } catch (e) {
      setState(() => _error = 'Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _join() async {
    if (_nameController.text.trim().isEmpty ||
        _codeController.text.trim().isEmpty) {
      setState(() => _error = 'Fill in both fields.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final code = _codeController.text.trim().toUpperCase();
      if (!kDemoMode) {
        await HouseholdService.instance.joinHousehold(
          code: code,
          displayName: _nameController.text.trim(),
        );
      }
      if (!mounted) return;
      _enterApp(code, _nameController.text.trim());
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showCodeDialog(String code) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Your household code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Share this with your housemates so they can join:'),
            const SizedBox(height: 12),
            SelectableText(
              code,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: 4,
                color: AppColors.quoteAccent,
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fridge Court')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    switch (_mode) {
      case _Mode.choose:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Welcome to Fridge Court',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Start a household for your place, or join one with a code.',
              style: TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.quoteAccent,
                ),
                onPressed: () => setState(() => _mode = _Mode.create),
                child: const Text('Start a new household'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () => setState(() => _mode = _Mode.join),
                child: const Text('Join with a code'),
              ),
            ),
          ],
        );

      case _Mode.create:
        return _form(
          title: 'Start a household',
          fields: [
            TextField(
              controller: _houseNameController,
              decoration: const InputDecoration(hintText: 'Household name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: 'Your name'),
            ),
          ],
          onSubmit: _create,
          submitLabel: 'Create',
        );

      case _Mode.join:
        return _form(
          title: 'Join a household',
          fields: [
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(hintText: 'Household code'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: 'Your name'),
            ),
          ],
          onSubmit: _join,
          submitLabel: 'Join',
        );
    }
  }

  Widget _form({
    required String title,
    required List<Widget> fields,
    required VoidCallback onSubmit,
    required String submitLabel,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        ...fields,
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, style: const TextStyle(color: AppColors.guilty)),
        ],
        const SizedBox(height: 20),
        SizedBox(
          height: 52,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.quoteAccent,
            ),
            onPressed: _loading ? null : onSubmit,
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(submitLabel),
          ),
        ),
        TextButton(
          onPressed: _loading
              ? null
              : () => setState(() {
                    _mode = _Mode.choose;
                    _error = null;
                  }),
          child: const Text('Back'),
        ),
      ],
    );
  }
}
