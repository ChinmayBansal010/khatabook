import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'remove_member_dialog.dart';

class GroupActionSheet extends StatelessWidget {
  final String groupId;
  const GroupActionSheet({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final db = FirebaseDatabase.instance.ref(uid);

    return SafeArea(
      child: Wrap(
        children: [
          const ListTile(
            title: Text(
              "Group actions",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          // 🔹 Remove member
          ListTile(
            leading: const Icon(Icons.person_remove),
            title: const Text("Remove a member"),
            onTap: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (_) => RemoveMemberDialog(groupId: groupId),
              );
            },
          ),

          // 🔹 Ungroup
          ListTile(
            leading: const Icon(Icons.group_off),
            title: const Text("Ungroup (keep users)"),
            onTap: () async {
              Navigator.pop(context);
              await _confirmUngroup(context, db);
            },
          ),

          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text(
              "Delete group & users",
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              Navigator.pop(context);
              await _confirmDeleteAll(context, db);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _confirmUngroup(
      BuildContext context, DatabaseReference db) async {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Ungroup users?"),
        content: const Text(
          "This will remove the group but keep all users and their data.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final membersSnap =
              await db.child('groups/$groupId/members').get();

              if (membersSnap.value != null) {
                final members =
                Map<String, dynamic>.from(membersSnap.value as Map);

                for (final userId in members.keys) {
                  await db.child('users/$userId/groupId').remove();
                }
              }

              await db.child('groups/$groupId').remove();
              if(dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
            },
            child: const Text("Ungroup"),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAll(
      BuildContext context, DatabaseReference db) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete everything?"),
        content: const Text(
          "This will permanently delete:\n• The group\n• All users inside\n• All transactions\n\nThis cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final membersSnap =
              await db.child('groups/$groupId/members').get();

              if (membersSnap.value != null) {
                final members =
                Map<String, dynamic>.from(membersSnap.value as Map);

                for (final userId in members.keys) {
                  await db.child('users/$userId').remove();
                }
              }

              await db.child('groups/$groupId').remove();
              if(context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}
