import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:async/async.dart';
import '../services/group_service.dart';

class EditGroupMembersDialog extends StatefulWidget {
  final String groupId;
  const EditGroupMembersDialog({super.key, required this.groupId});

  @override
  State<EditGroupMembersDialog> createState() =>
      _EditGroupMembersDialogState();
}

class _EditGroupMembersDialogState extends State<EditGroupMembersDialog> {
  final Map<String, bool> selected = {};

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final db = FirebaseDatabase.instance.ref(uid);

    return AlertDialog(
      title: const Text("Edit Members"),
      content: SizedBox(
        width: double.maxFinite,
        child: StreamBuilder<List<DatabaseEvent>>(
          stream: StreamZip([
            db.child('users').onValue,
            db.child('groups/${widget.groupId}').onValue,
          ]),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const CircularProgressIndicator();
            }

            final usersSnap = snapshot.data![0].snapshot;
            final groupSnap = snapshot.data![1].snapshot;

            final users = usersSnap.value != null
                ? Map<String, dynamic>.from(usersSnap.value as Map)
                : {};

            final group = Map<String, dynamic>.from(groupSnap.value as Map);
            final members = Map<String, dynamic>.from(group['members'] ?? {});

            for (final id in users.keys) {
              selected.putIfAbsent(id, () => members.containsKey(id));
            }

            return ListView(
              children: users.entries.map((e) {
                final userId = e.key;
                final user = Map<String, dynamic>.from(e.value);

                return CheckboxListTile(
                  title: Text(user['name']),
                  value: selected[userId],
                  onChanged: (v) {
                    setState(() {
                      selected[userId] = v ?? false;
                    });
                  },
                );
              }).toList(),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () async {
            final db = FirebaseDatabase.instance.ref(uid);

            final groupSnap =
            await db.child('groups/${widget.groupId}/members').get();

            final Map<String, dynamic> oldMembers = groupSnap.value != null
                ? Map<String, dynamic>.from(groupSnap.value as Map)
                : {};

            final Map<String, bool> newMembers = {};
            selected.forEach((userId, isSelected) {
              if (isSelected) newMembers[userId] = true;
            });

            final oldMemberIds = oldMembers.keys.toSet();
            final newMemberIds = newMembers.keys.toSet();

            for (final userId in oldMemberIds.difference(newMemberIds)) {
              await db.child('users/$userId/groupId').remove();
            }

            for (final userId in newMemberIds.difference(oldMemberIds)) {
              await db.child('users/$userId/groupId').set(widget.groupId);
            }

            await db
                .child('groups/${widget.groupId}/members')
                .set(newMembers);

            // 6️⃣ Recalculate balance
            await updateGroupTotalBalance(widget.groupId);

            Navigator.pop(context);
          },
          child: const Text("Save"),
        )
      ],
    );
  }
}