import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../dialogs/group_action_sheet.dart';
import 'group_detail_page.dart';
import '../dialogs/create_group_dialog.dart';

class GroupPage extends StatelessWidget {
  const GroupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final groupRef = FirebaseDatabase.instance.ref('$uid/groups');

    return Scaffold(
      body: StreamBuilder<DatabaseEvent>(
        stream: groupRef.onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("No Groups"));
          }

          final groups =
          Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);

          return ListView(
            padding: const EdgeInsets.all(10),
            children: groups.entries.map((entry) {
              final group = Map<String, dynamic>.from(entry.value);
              final balance = group['totalBalance'] ?? 0;

              return SafeArea(
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 4,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal.shade100,
                      child: const Icon(Icons.group, color: Colors.teal),
                    ),
                    title: Text(group['name'],
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Total balance"),
                    trailing: Text(
                      "₹${balance.abs()}",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: balance >= 0 ? Colors.red : Colors.green,
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GroupDetailPage(groupId: entry.key),
                        ),
                      );
                    },
                    onLongPress: () {
                      showModalBottomSheet(
                        context: context,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (_) => GroupActionSheet(groupId: entry.key),
                      );
                    },

                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.group_add),
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => const CreateGroupDialog(),
          );
        },
      ),
    );
  }
}