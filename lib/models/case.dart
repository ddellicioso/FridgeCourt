/// Status of a filed case as it moves through Fridge Court.
enum CaseStatus { pending, onTrial, guilty, notGuilty }

extension CaseStatusLabel on CaseStatus {
  String get label {
    switch (this) {
      case CaseStatus.pending:
        return 'Pending';
      case CaseStatus.onTrial:
        return 'On Trial';
      case CaseStatus.guilty:
        return 'Guilty';
      case CaseStatus.notGuilty:
        return 'Not Guilty';
    }
  }

  static CaseStatus fromName(String name) {
    return CaseStatus.values.firstWhere(
      (s) => s.name == name,
      orElse: () => CaseStatus.pending,
    );
  }
}

/// A single vote cast by a juror.
enum Vote { guilty, notGuilty }

extension VoteName on Vote {
  static Vote fromName(String name) {
    return Vote.values.firstWhere((v) => v.name == name);
  }
}

/// A filed "crime" case.
///
/// Votes are keyed by Firebase Auth uid (`votesByUid`), not just counted,
/// so "one vote per person" holds across real devices — a person voting
/// from a new phone is still the same uid, not a fresh vote slot.
class FridgeCase {
  final String id;
  final String crimeTitle;
  final String accused;
  final String reporter;
  final String evidenceNote;
  final CaseStatus status;
  final Map<String, Vote> votesByUid;
  final String? sentence;

  const FridgeCase({
    required this.id,
    required this.crimeTitle,
    required this.accused,
    required this.reporter,
    required this.evidenceNote,
    required this.status,
    this.votesByUid = const {},
    this.sentence,
  });

  int get guiltyVotes =>
      votesByUid.values.where((v) => v == Vote.guilty).length;
  int get notGuiltyVotes =>
      votesByUid.values.where((v) => v == Vote.notGuilty).length;

  Vote? voteOf(String uid) => votesByUid[uid];
  bool hasVoted(String uid) => votesByUid.containsKey(uid);

  FridgeCase copyWith({
    CaseStatus? status,
    Map<String, Vote>? votesByUid,
    String? sentence,
  }) {
    return FridgeCase(
      id: id,
      crimeTitle: crimeTitle,
      accused: accused,
      reporter: reporter,
      evidenceNote: evidenceNote,
      status: status ?? this.status,
      votesByUid: votesByUid ?? this.votesByUid,
      sentence: sentence ?? this.sentence,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'crimeTitle': crimeTitle,
      'accused': accused,
      'reporter': reporter,
      'evidenceNote': evidenceNote,
      'status': status.name,
      'votesByUid': votesByUid.map((uid, vote) => MapEntry(uid, vote.name)),
      'sentence': sentence,
    };
  }

  factory FridgeCase.fromMap(String id, Map<String, dynamic> map) {
    final rawVotes = (map['votesByUid'] as Map?) ?? {};
    return FridgeCase(
      id: id,
      crimeTitle: map['crimeTitle'] as String? ?? '',
      accused: map['accused'] as String? ?? '',
      reporter: map['reporter'] as String? ?? '',
      evidenceNote: map['evidenceNote'] as String? ?? '',
      status: CaseStatusLabel.fromName(map['status'] as String? ?? 'pending'),
      votesByUid: rawVotes.map(
        (uid, vote) => MapEntry(uid as String, VoteName.fromName(vote as String)),
      ),
      sentence: map['sentence'] as String?,
    );
  }
}