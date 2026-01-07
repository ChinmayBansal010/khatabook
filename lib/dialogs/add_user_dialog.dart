import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AddUserDialog extends StatefulWidget {
  const AddUserDialog({super.key});

  @override
  State<AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<AddUserDialog> {
  final TextEditingController nameController = TextEditingController();
  final uid = FirebaseAuth.instance.currentUser!.uid;
  late final DatabaseReference db = FirebaseDatabase.instance.ref(uid);

  Future<void> addUser() async {
    final name = nameController.text.trim();
    if (name.isEmpty) return;

    final userId = db.child('users').push().key!;

    await db.child('users/$userId').set({
      "name": name,
      "balance": 0,
      "transactions": {},
      "groupId": null,
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Add User"),
      content: TextField(
        controller: nameController,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: "User name",
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: addUser,
          child: const Text("Add"),
        ),
      ],
    );
  }
}
