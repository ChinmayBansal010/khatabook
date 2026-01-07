import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../dialogs/user_actions_sheet.dart';
import '../widgets/user_tile.dart';
import '../dialogs/edit_group_members_dialog.dart';
import 'user_page.dart';

class GroupDetailPage extends StatelessWidget {
  final String groupId;
  const GroupDetailPage({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final db = FirebaseDatabase.instance.ref(uid);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Group"),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => EditGroupMembersDialog(groupId: groupId),
              );
            },
          )
        ],
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: db.child('groups/$groupId').onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final group =
          Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
          final members =
          Map<String, dynamic>.from(group['members'] ?? {});
          final totalBalance = group['totalBalance'] ?? 0;
          final memberIds = members.keys.toList();

          return Column(
            children: [
              Card(
                margin: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 6,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: totalBalance >= 0
                          ? [Colors.red.shade300, Colors.red.shade600]
                          : [Colors.green.shade300, Colors.green.shade600],
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        group['name'],
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Total: ₹${totalBalance.abs()}",
                        style: TextStyle(
                          fontSize: 20,
                            fontWeight: FontWeight.bold,
                          color: Colors.white
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: StreamBuilder<DatabaseEvent>(
                  stream: db.child('users').onValue,
                  builder: (context, userSnap) {
                    if (!userSnap.hasData || userSnap.data!.snapshot.value == null) {
                      return const SizedBox();
                    }

                    final allUsers =
                    Map<String, dynamic>.from(userSnap.data!.snapshot.value as Map);

                    // build only group members
                    final usersInGroup = memberIds
                        .where((id) => allUsers.containsKey(id))
                        .map((id) {
                      final user = Map<String, dynamic>.from(allUsers[id]);
                      return {
                        'id': id,
                        'name': user['name'],
                        'balance': user['balance'] ?? 0,
                        'pinned': user['pinned'] == true,
                      };
                    })
                        .toList();

                    // ✅ SORT PINNED FIRST
                    usersInGroup.sort((a, b) {
                      final ap = a['pinned'] == true ? 1 : 0;
                      final bp = b['pinned'] == true ? 1 : 0;
                      return bp.compareTo(ap);
                    });

                    return ListView(
                      children: usersInGroup.map((user) {
                        return UserTile(
                          name: user['name'],
                          balance: user['balance'],
                          isPinned: user['pinned'],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UserPage(userId: user['id']),
                              ),
                            );
                          },
                          onLongPress: () {
                            showModalBottomSheet(
                              context: context,
                              shape: const RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.vertical(top: Radius.circular(20)),
                              ),
                              builder: (_) => UserActionsSheet(
                                userId: user['id'],
                                currentName: user['name'],
                                isPinned: user['pinned'],
                                groupId: groupId,
                              ),
                            );
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
