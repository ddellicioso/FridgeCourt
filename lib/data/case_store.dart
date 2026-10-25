import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/case.dart';
import '../data/crime_menu.dart';
import '../data/sentence_pool.dart';
import '../services/auth_service.dart';
import '../services/household_service.dart';

const _kVoteTimeout = Duration(hours: 24);

/// Firestore-backed store, scoped to one household. Cases live at
/// households/{householdCode}/cases/{caseId} and update in real time for
/// everyone in that household — this is what makes voting/case status
/// actually shared across housemates' devices.
///
/// Also doubles as the demo-video data source: `CaseStore.demo()` skips
/// Firestore/Auth entirely and runs on an in-memory, pre-seeded case
/// list instead (see lib/demo_mode.dart for the switch that picks this).
class CaseStore extends ChangeNotifier {
  CaseStore({required this.householdCode, required String displayName})
      : _offline = false,
        _displayName = displayName {
    _subscription = _casesRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(_onSnapshot, onError: (e) => debugPrint('CaseStore error: $e'));
    _loadMembers();
  }

  /// In-memory store pre-loaded with sample cases — no Firebase project,
  /// no network, fully interactive. Everything (filing a case, pleading,
  /// voting, nickname changes) just mutates the local list.
  CaseStore.demo({
    this.householdCode = 'DEMO42',
    String displayName = 'Maya',
  })  : _offline = true,
        _displayName = displayName {
    _members = ['Maya', 'Alex', 'Jordan'];
    if (!_members.contains(displayName)) _members.add(displayName);
    _cases = _seedDemoCases(displayName);
    unawaited(checkTimeouts());
  }

  final String householdCode;
  final bool _offline;
  String _displayName;

  List<FridgeCase> _cases = [];
  List<String> _members = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  List<FridgeCase> get cases => List.unmodifiable(_cases);
  String get displayName => _displayName;

  /// Everyone currently in the household — used for the "who did it?"
  /// picker on the report screen and for working out how many eligible
  /// jurors a case has.
  List<String> get householdMembers => List.unmodifiable(_members);

  String get myUid => _offline ? 'demo-uid' : AuthService.instance.currentUid;

  CollectionReference<Map<String, dynamic>> get _casesRef => FirebaseFirestore
      .instance
      .collection('households')
      .doc(householdCode)
      .collection('cases');

  Future<void> _loadMembers() async {
    try {
      _members = await HouseholdService.instance.getMemberNames(householdCode);
      notifyListeners();
    } catch (e) {
      debugPrint('CaseStore: could not load members: $e');
    }
  }

  /// Renames this device's nickname (household-wide), rejecting it if
  /// another member already has that name. Returns an error message on
  /// failure, or null on success.
  Future<String?> renameSelf(String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return 'Enter a name.';
    final normalized = trimmed.toLowerCase();
    final taken = _members.any(
      (m) => m.toLowerCase() == normalized && m.toLowerCase() != _displayName.toLowerCase(),
    );
    if (taken) return 'That nickname is already taken in this household.';

    if (_offline) {
      final old = _displayName;
      _members = [for (final m in _members) if (m == old) trimmed else m];
      _displayName = trimmed;
      notifyListeners();
      return null;
    }

    try {
      await HouseholdService.instance.updateNickname(
        code: householdCode,
        newName: trimmed,
      );
      _displayName = trimmed;
      await _loadMembers();
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  void _onSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    _cases = snapshot.docs
        .map((doc) => FridgeCase.fromMap(doc.id, doc.data()))
        .toList();
    notifyListeners();
    unawaited(checkTimeouts());
  }

  FridgeCase byId(String id) => _cases.firstWhere((c) => c.id == id);

  void _replaceLocal(String id, FridgeCase updated) {
    _cases = [
      for (final c in _cases) if (c.id == id) updated else c,
    ];
    notifyListeners();
  }

  bool _isAccuser(FridgeCase c) =>
      c.reporter.trim().toLowerCase() == _displayName.trim().toLowerCase();
  bool _isAccused(FridgeCase c) =>
      c.accused.trim().toLowerCase() == _displayName.trim().toLowerCase();

  /// Household members minus the accuser and the accused — the only
  /// people whose vote counts on a case.
  List<String> eligibleJurors(FridgeCase c) => _members.where((m) {
        final lower = m.trim().toLowerCase();
        return lower != c.accused.trim().toLowerCase() &&
            lower != c.reporter.trim().toLowerCase();
      }).toList();

  /// Cases on trial that this person hasn't voted on yet, and isn't
  /// blocked from voting on — "jury duty" pending for them.
  List<FridgeCase> get casesNeedingMyVote => _cases
      .where((c) =>
          c.status == CaseStatus.onTrial &&
          !c.hasVoted(myUid) &&
          !_isAccuser(c) &&
          !_isAccused(c))
      .toList();

  /// Cases where this person is the accused and still needs to plead.
  List<FridgeCase> get casesAwaitingMyPlea =>
      _cases.where((c) => c.status == CaseStatus.pending && _isAccused(c)).toList();

  /// Cases where this person is the one accused and it isn't resolved yet.
  List<FridgeCase> get casesWhereIAmAccused => _cases.where((c) {
        final unresolved =
            c.status == CaseStatus.pending || c.status == CaseStatus.onTrial;
        return _isAccused(c) && unresolved;
      }).toList();

  /// Everything this person has a pending action on, de-duplicated.
  List<FridgeCase> get pendingForMe {
    final seen = <String>{};
    final result = <FridgeCase>[];
    for (final c in [...casesWhereIAmAccused, ...casesNeedingMyVote]) {
      if (seen.add(c.id)) result.add(c);
    }
    return result;
  }

  Future<void> addCase({
    required String accused,
    required CrimeDef crime,
    String evidenceNote = '',
  }) async {
    if (_offline) {
      final newCase = FridgeCase(
        id: 'local-${DateTime.now().microsecondsSinceEpoch}',
        crimeTitle: crime.title,
        severity: crime.severity,
        accused: accused,
        reporter: _displayName,
        evidenceNote: evidenceNote,
        status: CaseStatus.pending,
        createdAt: DateTime.now(),
      );
      _cases = [newCase, ..._cases];
      notifyListeners();
      return;
    }
    await _casesRef.add({
      'crimeTitle': crime.title,
      'severity': crime.severity.name,
      'accused': accused,
      'reporter': _displayName,
      'evidenceNote': evidenceNote,
      'status': CaseStatus.pending.name,
      'votesByUid': <String, String>{},
      'sentence': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// The accused enters a plea. Guilty skips the trial entirely and goes
  /// straight to a (lighter) plea-deal sentence; not guilty opens jury
  /// voting.
  Future<void> enterPlea(String id, {required bool guilty}) async {
    final current = byId(id);
    if (guilty) {
      final sentence = _pickSentence(current, pleaDeal: true);
      await _setResolved(id, status: CaseStatus.guilty, sentence: sentence);
    } else {
      await _setStatus(id, CaseStatus.onTrial);
    }
  }

  Future<void> _setStatus(String id, CaseStatus status) async {
    if (_offline) {
      _replaceLocal(id, byId(id).copyWith(status: status));
      return;
    }
    await _casesRef.doc(id).update({'status': status.name});
  }

  Future<void> _setResolved(
    String id, {
    required CaseStatus status,
    required String sentence,
  }) async {
    if (_offline) {
      _replaceLocal(id, byId(id).copyWith(status: status, sentence: sentence));
      return;
    }
    await _casesRef.doc(id).update({'status': status.name, 'sentence': sentence});
  }

  /// Casts a vote. Returns false (and writes nothing) if this uid already
  /// voted, or if this person is the accuser/accused on this case (jurors
  /// only) — also enforced server-side by Firestore security rules for
  /// the one-vote-per-person part.
  Future<bool> castVote(String id, Vote vote) async {
    final current = byId(id);
    if (current.hasVoted(myUid)) return false;
    if (_isAccuser(current) || _isAccused(current)) return false;

    final updatedVotes = {...current.votesByUid, myUid: vote};

    if (_offline) {
      _replaceLocal(
        id,
        current.copyWith(votesByUid: updatedVotes, status: CaseStatus.onTrial),
      );
    } else {
      await _casesRef.doc(id).update({
        'votesByUid.$myUid': vote.name,
        'status': CaseStatus.onTrial.name,
      });
    }

    await _maybeAutoResolve(id);
    return true;
  }

  /// Once every eligible juror has voted, the verdict is automatic —
  /// majority wins (a tie counts as not guilty), and the sentence is
  /// drawn from the severity-matched pool.
  Future<void> _maybeAutoResolve(String id) async {
    final current = byId(id);
    if (current.status != CaseStatus.onTrial) return;

    final jurors = eligibleJurors(current);
    if (jurors.isEmpty) return; // nobody eligible to vote — leave it open
    if (current.votesByUid.length < jurors.length) return; // still waiting

    final guilty = current.guiltyVotes > current.notGuiltyVotes;
    final sentence = guilty
        ? _pickSentence(current, pleaDeal: false)
        : 'Case dismissed. No snacks were harmed.';
    await _setResolved(
      id,
      status: guilty ? CaseStatus.guilty : CaseStatus.notGuilty,
      sentence: sentence,
    );
  }

  /// Checked on every snapshot (Firestore mode) and worth calling once at
  /// startup in demo mode too: any case still "On Trial" more than 24h
  /// after filing gets auto-resolved on whatever votes it has, even if
  /// not every juror voted.
  Future<void> checkTimeouts() async {
    final now = DateTime.now();
    for (final c in _cases) {
      if (c.status != CaseStatus.onTrial) continue;
      if (c.createdAt == null) continue;
      if (now.difference(c.createdAt!) < _kVoteTimeout) continue;

      final guilty = c.guiltyVotes > c.notGuiltyVotes;
      final sentence = guilty
          ? _pickSentence(c, pleaDeal: false)
          : 'Case dismissed (timed out after 24h). No snacks were harmed.';
      await _setResolved(
        c.id,
        status: guilty ? CaseStatus.guilty : CaseStatus.notGuilty,
        sentence: sentence,
      );
    }
  }

  /// Picks a sentence from the right severity tier, avoiding whatever
  /// this same accused's most recent sentence was (so it doesn't repeat
  /// twice in a row for the same person).
  String _pickSentence(FridgeCase current, {required bool pleaDeal}) {
    final pool = (pleaDeal ? pleaDealPool : sentencePool)[current.severity]!;

    final priorForThisPerson = _cases.where((c) =>
        c.id != current.id &&
        c.sentence != null &&
        c.accused.trim().toLowerCase() == current.accused.trim().toLowerCase());
    final lastSentence =
        priorForThisPerson.isNotEmpty ? priorForThisPerson.first.sentence : null;

    final candidates = pool.where((s) => s != lastSentence).toList();
    final pickFrom = candidates.isEmpty ? pool : candidates;
    return pickFrom[Random().nextInt(pickFrom.length)];
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Sample cases for the demo video.
///
/// - demo-1: accused is YOU (whatever name you sign in with) and still
///   pending — lets the video show the plea step.
/// - demo-2: accused is Jordan, filed by Alex, already on trial — since
///   the household is only Maya/Alex/Jordan, YOU (if you're Maya) are
///   the only eligible juror, so casting one vote auto-resolves it live.
/// - demo-3: a plain pending case for list variety.
/// - demo-4: already resolved, guilty, so the verdict reveal is visible
///   immediately without doing anything.
List<FridgeCase> _seedDemoCases(String displayName) {
  final now = DateTime.now();
  return [
    FridgeCase(
      id: 'demo-1',
      crimeTitle: 'Grand theft leftovers',
      severity: Severity.major,
      accused: displayName,
      reporter: 'Alex',
      evidenceNote: 'Container came back suspiciously clean.',
      status: CaseStatus.pending,
      createdAt: now,
    ),
    FridgeCase(
      id: 'demo-2',
      crimeTitle: 'Took a labeled snack',
      severity: Severity.medium,
      accused: 'Jordan',
      reporter: 'Alex',
      evidenceNote: 'Wrapper found in the recycling, name tag still on it.',
      status: CaseStatus.onTrial,
      votesByUid: const {},
      createdAt: now,
    ),
    FridgeCase(
      id: 'demo-3',
      crimeTitle: 'Left dishes in the sink overnight',
      severity: Severity.minor,
      accused: 'Alex',
      reporter: 'Jordan',
      evidenceNote: '',
      status: CaseStatus.pending,
      createdAt: now,
    ),
    FridgeCase(
      id: 'demo-4',
      crimeTitle: 'Ghosted on a dish-duty swap',
      severity: Severity.major,
      accused: 'Jordan',
      reporter: 'Alex',
      evidenceNote: 'Agreed to swap Tuesday, never showed up to do dishes.',
      status: CaseStatus.guilty,
      sentence: 'Must do all grocery runs for the next two weeks.',
      votesByUid: const {'alex-uid': Vote.guilty},
      createdAt: now.subtract(const Duration(hours: 3)),
    ),
  ];
}
