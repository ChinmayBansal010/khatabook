import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class MoveToGroupSheet extends StatelessWidget {
  final String userId;
  final String currentGroupId;

  const MoveToGroupSheet({
    super.key,
    required this.userId,
    required this.currentGroupId,
  });

  @override
  Widget build(BuildContext context) {
    final db = FirebaseDatabase.instance.ref();

    return SafeArea(
      child: StreamBuilder<DatabaseEvent>(
        stream: db.child('groups').onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            );
          }

          final groups =
          Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);

          final otherGroups = groups.entries
              .where((e) => e.key != currentGroupId)
              .toList();

          if (otherGroups.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: Text("No other groups available"),
            );
          }

          return ListView(
            shrinkWrap: true,
            children: otherGroups.map((entry) {
              final groupId = entry.key;
              final group = Map<String, dynamic>.from(entry.value);

              return ListTile(
                leading: const Icon(Icons.group),
                title: Text(group['name']),
                onTap: () async {
                  // 1️⃣ remove from old group
                  await db
                      .child('groups/$currentGroupId/members/$userId')
                      .remove();

                  // 2️⃣ add to new group
                  await db
                      .child('groups/$groupId/members/$userId')
                      .set(true);

                  // 3️⃣ update user
                  await db
                      .child('users/$userId/groupId')
                      .set(groupId);

                  // 4️⃣ update balances
                  await _updateGroupTotal(currentGroupId);
                  await _updateGroupTotal(groupId);

                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Future<void> _updateGroupTotal(String groupId) async {
    final db = FirebaseDatabase.instance.ref();
    final groupSnap = await db.child('groups/$groupId').get();
    if (groupSnap.value == null) return;

    final group = Map<String, dynamic>.from(groupSnap.value as Map);
    final members = Map<String, dynamic>.from(group['members'] ?? {});

    int total = 0;
    for (final userId in members.keys) {
      final balSnap = await db.child('users/$userId/balance').get();
      total += int.tryParse(balSnap.value.toString()) ?? 0;
    }

    await db.child('groups/$groupId/totalBalance').set(total);
  }
}
