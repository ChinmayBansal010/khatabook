import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class RemoveMemberDialog extends StatelessWidget {
  final String groupId;
  const RemoveMemberDialog({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final db = FirebaseDatabase.instance.ref(uid);

    return AlertDialog(
      title: const Text("Remove member"),
      content: SizedBox(
        width: double.maxFinite,
        child: StreamBuilder<DatabaseEvent>(
          stream: db.child('groups/$groupId/members').onValue,
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final members =
            Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);

            return ListView(
              shrinkWrap: true,
              children: members.keys.map((userId) {
                return StreamBuilder<DatabaseEvent>(
                  stream: db.child('users/$userId').onValue,
                  builder: (context, snap) {
                    if (!snap.hasData || snap.data!.snapshot.value == null) {
                      return const SizedBox();
                    }

                    final user =
                    Map<String, dynamic>.from(snap.data!.snapshot.value as Map);

                    return ListTile(
                      title: Text(user['name']),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () async {
                          await db
                              .child('groups/$groupId/members/$userId')
                              .remove();
                          await db.child('users/$userId/groupId').remove();
                          Navigator.pop(context);
                        },
                      ),
                    );
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
          child: const Text("Close"),
        ),
      ],
    );
  }
}
