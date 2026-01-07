import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/group_service.dart';

class CreateGroupDialog extends StatefulWidget {
  const CreateGroupDialog({super.key});

  @override
  State<CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<CreateGroupDialog> {
  final TextEditingController groupNameController = TextEditingController();
  final Map<String, bool> selectedUsers = {};
  final uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    final userRef = FirebaseDatabase.instance.ref('$uid/users');

    return AlertDialog(
      title: const Text("Create Group"),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: groupNameController,
              decoration: const InputDecoration(
                hintText: "Group name",
              ),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: StreamBuilder<DatabaseEvent>(
                stream: userRef.onValue,
                builder: (context, snapshot) {
                  if (!snapshot.hasData ||
                      snapshot.data!.snapshot.value == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final users = Map<String, dynamic>.from(
                      snapshot.data!.snapshot.value as Map);

                  return ListView(
                    children: users.entries
                        .where((e) => e.value['groupId'] == null)
                        .map((entry) {
                      final userId = entry.key;
                      final user =
                      Map<String, dynamic>.from(entry.value);

                      selectedUsers.putIfAbsent(userId, () => false);

                      return CheckboxListTile(
                        title: Text(user['name']),
                        value: selectedUsers[userId],
                        onChanged: (val) {
                          setState(() {
                            selectedUsers[userId] = val ?? false;
                          });
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: createGroup,
          child: const Text("Create"),
        ),
      ],
    );
  }

  Future<void> createGroup() async {
    final name = groupNameController.text.trim();
    if (name.isEmpty) return;

    final members = <String, bool>{};

    selectedUsers.forEach((key, value) {
      if (value) members[key] = true;
    });

    if (members.isEmpty) return;

    final db = FirebaseDatabase.instance.ref(uid);
    final groupId = db.child('groups').push().key!;

    // create group
    await db.child('groups/$groupId').set({
      "name": name,
      "members": members,
      "totalBalance": 0,
    });

    for (final userId in members.keys) {
      await db.child('users/$userId/groupId').set(groupId);
    }

    await updateGroupTotalBalance(groupId);
    Navigator.pop(context);
  }

}