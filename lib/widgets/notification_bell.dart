import 'package:flutter/material.dart';
import '../data/case_store.dart';
import '../models/case.dart';
import '../theme/app_colors.dart';
import '../screens/verdict_screen.dart';

/// In-app notification bell: badges how many cases need this person's
/// attention (jury duty pending, or they're the accused) and opens a
/// sheet listing them. Not a push notification — this only shows up
/// while the app is open, which matches the solo scope (real push
/// notifications are a Won't Have for now).
class NotificationBell extends StatelessWidget {
  final CaseStore store;

  const NotificationBell({super.key, required this.store});

  void _openSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return AnimatedBuilder(
          animation: store,
          builder: (context, _) {
            final pending = store.pendingForMe;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Needs your attention',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (pending.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          "Nothing pending. You're in the clear (for now).",
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    else
                      ...pending.map((c) => _PendingTile(
                            fridgeCase: c,
                            store: store,
                            onTap: () {
                              Navigator.pop(context); // close sheet
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => VerdictScreen(
                                    store: store,
                                    caseId: c.id,
                                  ),
                                ),
                              );
                            },
                          )),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final count = store.pendingForMe.length;
        return IconButton(
          tooltip: 'Needs your attention',
          onPressed: () => _openSheet(context),
          icon: Badge(
            label: Text('$count'),
            isLabelVisible: count > 0,
            backgroundColor: AppColors.guilty,
            child: const Icon(Icons.notifications_outlined),
          ),
        );
      },
    );
  }
}

class _PendingTile extends StatelessWidget {
  final FridgeCase fridgeCase;
  final CaseStore store;
  final VoidCallback onTap;

  const _PendingTile({
    required this.fridgeCase,
    required this.store,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iAmAccused = fridgeCase.accused.trim().toLowerCase() ==
        store.displayName.trim().toLowerCase();
    final reason = !iAmAccused
        ? 'Your vote is needed'
        : (fridgeCase.status == CaseStatus.pending
            ? 'Enter your plea'
            : "You're accused — on trial");

    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: Icon(
        iAmAccused ? Icons.gavel : Icons.how_to_vote,
        color: AppColors.quoteAccent,
      ),
      title: Text(
        fridgeCase.crimeTitle,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(reason),
    );
  }
}
