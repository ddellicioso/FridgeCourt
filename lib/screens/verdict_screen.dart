import 'package:flutter/material.dart';
import '../data/case_store.dart';
import '../models/case.dart';
import '../theme/app_colors.dart';
import '../widgets/status_pill.dart';
import '../widgets/verdict_button.dart';

/// Suggested joke sentences — Could Have: let the judge pick a random
/// one when the jury convicts. For now the user types their own.
class VerdictScreen extends StatefulWidget {
  final CaseStore store;
  final String caseId;

  const VerdictScreen({super.key, required this.store, required this.caseId});

  @override
  State<VerdictScreen> createState() => _VerdictScreenState();
}

class _VerdictScreenState extends State<VerdictScreen> {
  final _sentenceController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _sentenceController.dispose();
    super.dispose();
  }

  Future<void> _vote(Vote vote) async {
    setState(() => _busy = true);
    try {
      final accepted = await widget.store.castVote(widget.caseId, vote);
      if (!accepted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You already voted on this case.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _closeCase(bool guilty) async {
    String? sentence;
    if (guilty) {
      sentence = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Pass sentence'),
          content: TextField(
            controller: _sentenceController,
            decoration: const InputDecoration(
              hintText: 'e.g. Must do dishes for a week',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, _sentenceController.text),
              child: const Text('Confirm'),
            ),
          ],
        ),
      );
      if (sentence == null || sentence.trim().isEmpty) return;
    }

    setState(() => _busy = true);
    try {
      await widget.store.closeCase(
        widget.caseId,
        guilty: guilty,
        sentence: guilty ? sentence : 'Case dismissed. No snacks were harmed.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Case File')),
      body: AnimatedBuilder(
        animation: widget.store,
        builder: (context, _) {
          final fridgeCase = widget.store.byId(widget.caseId);
          final myUid = widget.store.myUid;
          final isDecided = fridgeCase.status == CaseStatus.guilty ||
              fridgeCase.status == CaseStatus.notGuilty;
          final myVote = fridgeCase.voteOf(myUid);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      fridgeCase.crimeTitle,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  StatusPill(status: fridgeCase.status),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Accused: ${fridgeCase.accused}  ·  Filed by ${fridgeCase.reporter}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Evidence',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        fridgeCase.evidenceNote.isEmpty
                            ? 'No evidence note was added.'
                            : fridgeCase.evidenceNote,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              if (isDecided) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.quoteAccent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.quoteAccent.withOpacity(0.25),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'The fridge says…',
                        style: TextStyle(
                          color: AppColors.quoteAccent,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        fridgeCase.status == CaseStatus.guilty
                            ? 'GUILTY.'
                            : 'NOT GUILTY.',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (fridgeCase.sentence != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          fridgeCase.sentence!,
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
              ] else ...[
                Text(
                  '${fridgeCase.guiltyVotes} guilty · ${fridgeCase.notGuiltyVotes} not guilty',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                if (myVote != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.cardBorder,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'You voted: ${myVote == Vote.guilty ? 'Guilty' : 'Not Guilty'}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: VerdictButton(
                          kind: VerdictButtonKind.notGuilty,
                          label: 'Vote Not Guilty',
                          onPressed: _busy ? () {} : () => _vote(Vote.notGuilty),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: VerdictButton(
                          kind: VerdictButtonKind.guilty,
                          label: 'Vote Guilty',
                          onPressed: _busy ? () {} : () => _vote(Vote.guilty),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                const Divider(color: AppColors.cardBorder),
                const SizedBox(height: 12),
                const Text(
                  'Judge\'s bench',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _busy ? null : () => _closeCase(false),
                        child: const Text('Dismiss Case'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.guilty,
                        ),
                        onPressed: _busy ? null : () => _closeCase(true),
                        child: const Text('Convict'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}