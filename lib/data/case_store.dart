import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/case.dart';
import '../services/auth_service.dart';

/// Firestore-backed store, scoped to one household. Cases live at
/// households/{householdCode}/cases/{caseId} and update in real time for
/// everyone in that household — this is what makes voting/case status
/// actually shared across housemates' devices.
class CaseStore extends ChangeNotifier {
  CaseStore({required this.householdCode, required this.displayName}) {
    _subscription = _casesRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(_onSnapshot, onError: (e) => debugPrint('CaseStore error: $e'));
  }

  final String householdCode;
  final String displayName;

  List<FridgeCase> _cases = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  List<FridgeCase> get cases => List.unmodifiable(_cases);

  String get myUid => AuthService.instance.currentUid;

  CollectionReference<Map<String, dynamic>> get _casesRef => FirebaseFirestore
      .instance
      .collection('households')
      .doc(householdCode)
      .collection('cases');

  void _onSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    _cases = snapshot.docs
        .map((doc) => FridgeCase.fromMap(doc.id, doc.data()))
        .toList();
    notifyListeners();
  }

  FridgeCase byId(String id) => _cases.firstWhere((c) => c.id == id);

  Future<void> addCase({
    required String crimeTitle,
    required String accused,
    required String evidenceNote,
  }) async {
    await _casesRef.add({
      'crimeTitle': crimeTitle,
      'accused': accused,
      'reporter': displayName,
      'evidenceNote': evidenceNote,
      'status': CaseStatus.pending.name,
      'votesByUid': <String, String>{},
      'sentence': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Casts a vote. Returns false (and writes nothing) if this uid already
  /// voted on the case — checked against the latest local snapshot, and
  /// also enforced by Firestore security rules server-side.
  Future<bool> castVote(String id, Vote vote) async {
    final current = byId(id);
    if (current.hasVoted(myUid)) return false;

    await _casesRef.doc(id).update({
      'votesByUid.$myUid': vote.name,
      'status': CaseStatus.onTrial.name,
    });
    return true;
  }

  Future<void> closeCase(String id, {required bool guilty, String? sentence}) async {
    await _casesRef.doc(id).update({
      'status': (guilty ? CaseStatus.guilty : CaseStatus.notGuilty).name,
      'sentence': sentence,
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}