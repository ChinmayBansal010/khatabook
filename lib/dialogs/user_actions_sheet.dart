import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import '../widgets/move_to_group_sheet.dart';

class UserActionsSheet extends StatelessWidget {
  final String userId;
  final String currentName;
  final bool isPinned;
  final String? groupId;

  const UserActionsSheet({
    super.key,
    required this.userId,
    required this.currentName,
    this.isPinned = false,
    this.groupId,
  });

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final db = FirebaseDatabase.instance.ref(uid);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text("Rename user"),
            onTap: () async {
              Navigator.pop(context);

              final controller =
              TextEditingController(text: currentName);

              showDialog(
                context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text("Update name"),
                    content: TextField(
                      controller: controller,
                      autofocus: true,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text("Cancel"),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final newName = controller.text.trim();
                          if (newName.isNotEmpty) {
                            await db.child('users/$userId/name').set(newName);
                          }
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                        },
                        child: const Text("Save"),
                      ),
                    ],
                  ),
              );
            },
          ),
          if (groupId != null)
            ListTile(
              leading: const Icon(Icons.group_off),
              title: const Text("Remove from group"),
              onTap: () {
                Navigator.pop(context);

                showDialog(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text("Remove from group?"),
                    content: const Text(
                      "This will move the user back to normal users. Transactions stay intact.",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text("Cancel"),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final db = FirebaseDatabase.instance.ref(uid);

                          await db
                              .child('groups/$groupId/members/$userId')
                              .remove();

                          await db.child('users/$userId/groupId').remove();

                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                        },
                        child: const Text("Remove"),
                      ),
                    ],
                  ),
                );
              },
            ),
          if (groupId != null)
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text("Move to another group"),
              onTap: () {
                Navigator.pop(context);

                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (_) => MoveToGroupSheet(
                    userId: userId,
                    currentGroupId: groupId!,
                  ),
                );
              },
            ),
          ListTile(
            leading: Icon(
              isPinned ? Icons.push_pin : Icons.push_pin_outlined,
            ),
            title: Text(isPinned ? "Unpin user" : "Pin user"),
            onTap: () async {
              await db.child('users/$userId/pinned').set(!isPinned);
              Navigator.pop(context);
            },
          ),

          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text(
              "Delete user",
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              Navigator.pop(context);

              showDialog(
                context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text("Delete user?"),
                    content: const Text(
                      "This will permanently delete the user and all their transactions.\n\nThis action cannot be undone.",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text("Cancel"),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () async {
                          if (groupId != null) {
                            await db.child('groups/$groupId/members/$userId').remove();
                          }

                          await db.child('users/$userId').remove();

                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                        },
                        child: const Text("Delete"),
                      ),
                    ],
                  ),
              );
            },
          ),
        ],
      ),
    );
  }
}
