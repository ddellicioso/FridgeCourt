import 'package:flutter/material.dart';
import '../data/case_store.dart';
import '../services/household_service.dart';
import '../theme/app_colors.dart';
import '../widgets/case_card.dart';
import '../widgets/notification_bell.dart';
import 'housecode_screen.dart';
import 'report_screen.dart';
import 'verdict_screen.dart';

class HomeScreen extends StatelessWidget {
  final CaseStore store;

  const HomeScreen({super.key, required this.store});

  Future<void> _editNickname(BuildContext context) async {
    final controller = TextEditingController(text: store.displayName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit your nickname'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Courtroom nickname'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (newName == null || !context.mounted) return;

    final error = await store.renameSelf(newName);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Nickname updated.')),
    );
  }

  Future<void> _leaveHousehold(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave this household?'),
        content: const Text(
          "This just forgets the household on this device — it doesn't "
          'delete anything. You can rejoin with the code any time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await HouseholdService.instance.forgetMembership();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HousecodeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fridge Court · ${store.householdCode}'),
        actions: [
          NotificationBell(store: store),
          IconButton(
            icon: const Icon(Icons.badge_outlined),
            tooltip: 'Edit nickname',
            onPressed: () => _editNickname(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Leave household',
            onPressed: () => _leaveHousehold(context),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final cases = store.cases;
          if (cases.isEmpty) {
            return const Center(
              child: Text(
                'No cases yet.\nEveryone is behaving (suspiciously).',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
            itemCount: cases.length,
            itemBuilder: (context, index) {
              final c = cases[index];
              final awaitingMyPlea =
                  store.casesAwaitingMyPlea.any((x) => x.id == c.id);
              final needsMyVote =
                  store.casesNeedingMyVote.any((x) => x.id == c.id);
              final iAmAccused =
                  store.casesWhereIAmAccused.any((x) => x.id == c.id);
              final needsAttention = awaitingMyPlea || needsMyVote || iAmAccused;
              final reason = awaitingMyPlea
                  ? 'Enter your plea'
                  : (needsMyVote
                      ? 'Your vote is needed'
                      : (iAmAccused ? "You're accused — on trial" : null));

              return CaseCard(
                fridgeCase: c,
                needsMyAttention: needsAttention,
                attentionReason: reason,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => VerdictScreen(store: store, caseId: c.id),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ReportScreen(store: store)),
        ),
        backgroundColor: AppColors.quoteAccent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.gavel),
        label: const Text('File a crime'),
      ),
    );
  }
}
