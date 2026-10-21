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
}

/// A single vote cast by a juror.
enum Vote { guilty, notGuilty }

/// A filed "crime" case.
class FridgeCase {
  final String id;
  final String crimeTitle;
  final String accused;
  final String reporter;
  final String evidenceNote;
  final CaseStatus status;
  final List<Vote> votes;
  final String? sentence;

  const FridgeCase({
    required this.id,
    required this.crimeTitle,
    required this.accused,
    required this.reporter,
    required this.evidenceNote,
    required this.status,
    this.votes = const [],
    this.sentence,
  });

  int get guiltyVotes => votes.where((v) => v == Vote.guilty).length;
  int get notGuiltyVotes => votes.where((v) => v == Vote.notGuilty).length;

  FridgeCase copyWith({
    CaseStatus? status,
    List<Vote>? votes,
    String? sentence,
  }) {
    return FridgeCase(
      id: id,
      crimeTitle: crimeTitle,
      accused: accused,
      reporter: reporter,
      evidenceNote: evidenceNote,
      status: status ?? this.status,
      votes: votes ?? this.votes,
      sentence: sentence ?? this.sentence,
    );
  }
}
