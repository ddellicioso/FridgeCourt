import 'package:flutter/foundation.dart';
import '../models/case.dart';

/// In-memory store standing in for Firestore for now.
/// Swap the body of these methods for Firestore calls once the
/// Must-have UI flow is confirmed — the screens only depend on this
/// class, not on how the data is stored.
class CaseStore extends ChangeNotifier {
  CaseStore() {
    _cases.addAll(_seed());
  }

  final List<FridgeCase> _cases = [];

  List<FridgeCase> get cases => List.unmodifiable(_cases);

  FridgeCase byId(String id) => _cases.firstWhere((c) => c.id == id);

  void addCase(FridgeCase newCase) {
    _cases.insert(0, newCase);
    notifyListeners();
  }

  void castVote(String id, Vote vote) {
    final index = _cases.indexWhere((c) => c.id == id);
    if (index == -1) return;
    final current = _cases[index];
    final updatedVotes = [...current.votes, vote];
    _cases[index] = current.copyWith(
      votes: updatedVotes,
      status: CaseStatus.onTrial,
    );
    notifyListeners();
  }

  void closeCase(String id, {required bool guilty, String? sentence}) {
    final index = _cases.indexWhere((c) => c.id == id);
    if (index == -1) return;
    final current = _cases[index];
    _cases[index] = current.copyWith(
      status: guilty ? CaseStatus.guilty : CaseStatus.notGuilty,
      sentence: sentence,
    );
    notifyListeners();
  }

  List<FridgeCase> _seed() => [
        const FridgeCase(
          id: 'c1',
          crimeTitle: 'Theft of the last dumpling',
          accused: 'Sam',
          reporter: 'Jordan',
          evidenceNote: 'Fridge cam caught him mid-bite at 1am.',
          status: CaseStatus.onTrial,
          votes: [Vote.guilty, Vote.guilty, Vote.notGuilty],
        ),
        const FridgeCase(
          id: 'c2',
          crimeTitle: 'Abandoned dishes, 3 days running',
          accused: 'Priya',
          reporter: 'Sam',
          evidenceNote: 'Photo attached, smell reported by two witnesses.',
          status: CaseStatus.pending,
        ),
        const FridgeCase(
          id: 'c3',
          crimeTitle: 'Unauthorized use of the good mug',
          accused: 'Jordan',
          reporter: 'Priya',
          evidenceNote: 'Mug found in his room. No alibi offered.',
          status: CaseStatus.guilty,
          sentence: 'Must wash all mugs for one week.',
        ),
      ];
}
