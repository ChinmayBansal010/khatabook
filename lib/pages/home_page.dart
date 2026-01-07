import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../dialogs/add_user_dialog.dart';
import '../dialogs/user_actions_sheet.dart';
import '../widgets/user_tile.dart';
import 'user_page.dart';

class HomePage extends StatelessWidget {
  final ScrollController scrollController;
  const HomePage({super.key, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final dbRef = FirebaseDatabase.instance.ref('$uid/users');

    return Scaffold(
      // appBar: AppBar(title: const Text("Khata")),
      body: StreamBuilder<DatabaseEvent>(
        stream: dbRef.onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("No Users"));
          }

          final users =
          Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);

          final userList = users.entries.toList();

          userList.sort((a, b) {
            final ap = a.value['pinned'] == true ? 1 : 0;
            final bp = b.value['pinned'] == true ? 1 : 0;
            return bp.compareTo(ap);
          });

          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(10),
            children: userList
                .where((entry) => entry.value['groupId'] == null)
                .map((entry) {
              final userId = entry.key;
              final user = Map<String, dynamic>.from(entry.value);
              final int balance = user['balance'] ?? 0;

              return UserTile(
                name: user['name'],
                balance: balance,
                isPinned: user['pinned'] == true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserPage(userId: userId),
                    ),
                  );
                },
                onLongPress: () {
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    builder: (_) => UserActionsSheet(
                      userId: userId,
                      currentName: user['name'],
                      isPinned: user['pinned'] == true,
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.person_add_alt_1),
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => const AddUserDialog(),
          );
        },
      ),
    );
  }
}