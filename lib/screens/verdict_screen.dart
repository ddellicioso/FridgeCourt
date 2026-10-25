import 'package:flutter/material.dart';
import '../data/case_store.dart';
import '../models/case.dart';
import '../theme/app_colors.dart';
import '../widgets/status_pill.dart';
import '../widgets/verdict_button.dart';

/// The case file: plea step (if you're the accused and it's still
/// pending), jury voting (if it's on trial and you're an eligible
/// juror), or the verdict reveal (once it's resolved). The verdict
/// itself is always automatic — see CaseStore._maybeAutoResolve /
/// checkTimeouts — there's no manual "judge" override here.
class VerdictScreen extends StatefulWidget {
  final CaseStore store;
  final String caseId;

  const VerdictScreen({super.key, required this.store, required this.caseId});

  @override
  State<VerdictScreen> createState() => _VerdictScreenState();
}

class _VerdictScreenState extends State<VerdictScreen> {
  bool _busy = false;

  Future<void> _plead(bool guilty) async {
    setState(() => _busy = true);
    try {
      await widget.store.enterPlea(widget.caseId, guilty: guilty);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _vote(Vote vote) async {
    setState(() => _busy = true);
    try {
      final accepted = await widget.store.castVote(widget.caseId, vote);
      if (!accepted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't record that vote.")),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  bool _isMe(String name) =>
      name.trim().toLowerCase() == widget.store.displayName.trim().toLowerCase();

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
          final isAccused = _isMe(fridgeCase.accused);
          final isAccuser = _isMe(fridgeCase.reporter);

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
              const SizedBox(height: 6),
              Text(
                '${fridgeCase.severity.label} severity',
                style: const TextStyle(
                  color: AppColors.quoteAccent,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
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

              if (isDecided)
                _VerdictReveal(fridgeCase: fridgeCase)
              else if (fridgeCase.status == CaseStatus.pending)
                _PleaSection(
                  isAccused: isAccused,
                  accused: fridgeCase.accused,
                  busy: _busy,
                  onPlead: _plead,
                )
              else
                _TrialSection(
                  fridgeCase: fridgeCase,
                  isAccuser: isAccuser,
                  isAccused: isAccused,
                  myVote: myVote,
                  busy: _busy,
                  onVote: _vote,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _VerdictReveal extends StatelessWidget {
  final FridgeCase fridgeCase;
  const _VerdictReveal({required this.fridgeCase});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.quoteAccent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.quoteAccent.withOpacity(0.25)),
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
            fridgeCase.status == CaseStatus.guilty ? 'GUILTY.' : 'NOT GUILTY.',
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
    );
  }
}

/// Shown while the case is pending — the accused pleads, everyone else
/// just sees that it's waiting.
class _PleaSection extends StatelessWidget {
  final bool isAccused;
  final String accused;
  final bool busy;
  final Future<void> Function(bool guilty) onPlead;

  const _PleaSection({
    required this.isAccused,
    required this.accused,
    required this.busy,
    required this.onPlead,
  });

  @override
  Widget build(BuildContext context) {
    if (!isAccused) {
      return Text(
        'Waiting for $accused to enter a plea.',
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How do you plead?',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Guilty skips the trial and gets you a lighter plea-deal sentence. '
          'Not guilty sends it to the jury.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: VerdictButton(
                kind: VerdictButtonKind.notGuilty,
                label: 'Plead Not Guilty',
                onPressed: busy ? () {} : () => onPlead(false),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: VerdictButton(
                kind: VerdictButtonKind.guilty,
                label: 'Plead Guilty',
                onPressed: busy ? () {} : () => onPlead(true),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Shown while the case is on trial — jury voting, with the accuser and
/// accused blocked from casting a vote on their own case.
class _TrialSection extends StatelessWidget {
  final FridgeCase fridgeCase;
  final bool isAccuser;
  final bool isAccused;
  final Vote? myVote;
  final bool busy;
  final Future<void> Function(Vote vote) onVote;

  const _TrialSection({
    required this.fridgeCase,
    required this.isAccuser,
    required this.isAccused,
    required this.myVote,
    required this.busy,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${fridgeCase.guiltyVotes} guilty · ${fridgeCase.notGuiltyVotes} not guilty',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        if (isAccuser || isAccused)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              "You can't vote on your own case — the jury's got this.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          )
        else if (myVote != null)
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
          )
        else
          Row(
            children: [
              Expanded(
                child: VerdictButton(
                  kind: VerdictButtonKind.notGuilty,
                  label: 'Vote Not Guilty',
                  onPressed: busy ? () {} : () => onVote(Vote.notGuilty),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: VerdictButton(
                  kind: VerdictButtonKind.guilty,
                  label: 'Vote Guilty',
                  onPressed: busy ? () {} : () => onVote(Vote.guilty),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
