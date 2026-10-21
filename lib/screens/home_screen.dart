import 'package:flutter/material.dart';
import '../data/case_store.dart';
import '../theme/app_colors.dart';
import '../widgets/case_card.dart';
import 'report_screen.dart';
import 'verdict_screen.dart';

class HomeScreen extends StatelessWidget {
  final CaseStore store;

  const HomeScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fridge Court')),
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
              return CaseCard(
                fridgeCase: c,
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
