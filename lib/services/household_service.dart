import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

const _kHouseholdCodeKey = 'household_code';
const _kDisplayNameKey = 'display_name';

/// Creating, joining, and remembering which "house" this device belongs
/// to. A household is just a Firestore doc at households/{code}; cases
/// live in the households/{code}/cases subcollection (see CaseStore).
class HouseholdService {
  HouseholdService._internal();
  static final HouseholdService instance = HouseholdService._internal();

  final _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _households =>
      _firestore.collection('households');

  /// Reads what was saved locally last time the app ran, if anything.
  Future<({String code, String name})?> getSavedMembership() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_kHouseholdCodeKey);
    final name = prefs.getString(_kDisplayNameKey);
    if (code == null || name == null) return null;
    return (code: code, name: name);
  }

  Future<void> _saveMembership(String code, String displayName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kHouseholdCodeKey, code);
    await prefs.setString(_kDisplayNameKey, displayName);
  }

  /// Leaves the household saved on this device (does not delete the
  /// household itself) — useful for "wrong code" / testing.
  Future<void> forgetMembership() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kHouseholdCodeKey);
    await prefs.remove(_kDisplayNameKey);
  }

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no 0/O/1/I confusion
    final rand = Random.secure();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  /// Creates a new household, retrying on the rare code collision.
  Future<String> createHousehold({
    required String houseName,
    required String displayName,
  }) async {
    await AuthService.instance.ensureSignedIn();
    final uid = AuthService.instance.currentUid;

    for (var attempt = 0; attempt < 5; attempt++) {
      final code = _generateCode();
      final doc = _households.doc(code);
      final existing = await doc.get();
      if (existing.exists) continue; // collision, try another code

      await doc.set({
        'houseName': houseName,
        'createdAt': FieldValue.serverTimestamp(),
        'members': {uid: displayName},
      });
      await _saveMembership(code, displayName);
      return code;
    }
    throw Exception('Could not generate a unique household code, try again.');
  }

  /// Joins an existing household by code. Throws if the code doesn't exist,
  /// or if the nickname is already taken by someone else in it.
  Future<void> joinHousehold({
    required String code,
    required String displayName,
  }) async {
    await AuthService.instance.ensureSignedIn();
    final uid = AuthService.instance.currentUid;
    final normalizedCode = code.trim().toUpperCase();

    final doc = _households.doc(normalizedCode);
    final snapshot = await doc.get();
    if (!snapshot.exists) {
      throw Exception('No household found with that code.');
    }

    _assertNicknameFree(snapshot, displayName, excludingUid: uid);

    await doc.update({'members.$uid': displayName});
    await _saveMembership(normalizedCode, displayName);
  }

  /// All current member nicknames in a household, for pickers (e.g. "who
  /// did it?" on the report screen).
  Future<List<String>> getMemberNames(String code) async {
    final doc = await _households.doc(code).get();
    final members = (doc.data()?['members'] as Map?) ?? {};
    return members.values.map((v) => v.toString()).toList();
  }

  /// Changes this device's nickname in the household, rejecting it if
  /// another member already has that name (case-insensitive).
  Future<void> updateNickname({
    required String code,
    required String newName,
  }) async {
    await AuthService.instance.ensureSignedIn();
    final uid = AuthService.instance.currentUid;
    final doc = _households.doc(code);
    final snapshot = await doc.get();
    if (!snapshot.exists) {
      throw Exception('Household not found.');
    }

    _assertNicknameFree(snapshot, newName, excludingUid: uid);

    await doc.update({'members.$uid': newName.trim()});
    await _saveMembership(code, newName.trim());
  }

  void _assertNicknameFree(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    String name, {
    required String excludingUid,
  }) {
    final members = (snapshot.data()?['members'] as Map?) ?? {};
    final normalized = name.trim().toLowerCase();
    final taken = members.entries.any((e) =>
        e.key != excludingUid &&
        (e.value as String).trim().toLowerCase() == normalized);
    if (taken) {
      throw Exception('That nickname is already taken in this household.');
    }
  }
}
