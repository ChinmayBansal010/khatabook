import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

final uid = FirebaseAuth.instance.currentUser!.uid;
final _db = FirebaseDatabase.instance.ref(uid);

Future<void> updateGroupTotalBalance(String groupId) async {
  final snap = await _db.child('groups/$groupId').get();
  if (snap.value == null) return;

  final group = Map<String, dynamic>.from(snap.value as Map);
  final members = Map<String, dynamic>.from(group['members'] ?? {});

  int total = 0;
  for (final userId in members.keys) {
    final balSnap = await _db.child('users/$userId/balance').get();
    total += int.tryParse(balSnap.value.toString()) ?? 0;
  }

  await _db.child('groups/$groupId/totalBalance').set(total);
}
