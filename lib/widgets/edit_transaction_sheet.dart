import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class EditTransactionSheet extends StatefulWidget {
  final String userId;
  final String transactionId;
  final Map<String, dynamic> oldData;

  const EditTransactionSheet({
    super.key,
    required this.userId,
    required this.transactionId,
    required this.oldData,
  });

  @override
  State<EditTransactionSheet> createState() => _EditTransactionSheetState();
}

class _EditTransactionSheetState extends State<EditTransactionSheet> {
  late TextEditingController noteController;
  late TextEditingController amountController;

  @override
  void initState() {
    super.initState();
    noteController = TextEditingController(text: widget.oldData['note']);
    amountController = TextEditingController(
      text: widget.oldData['amount'].abs().toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = FirebaseDatabase.instance.ref();

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Edit Transaction",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: noteController,
            decoration: const InputDecoration(
              labelText: "Note",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Amount",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),

          /// SAVE BUTTON
          ElevatedButton(
            onPressed: () async {
              final newAmount = int.tryParse(amountController.text);
              if (newAmount == null || newAmount <= 0) return;

              final wasCredit = widget.oldData['amount'] < 0;
              final signedNewAmount =
              wasCredit ? -newAmount : newAmount;

              final oldAmount = widget.oldData['amount'];
              final delta = signedNewAmount - oldAmount;

              // update transaction
              await db
                  .child(
                  'users/${widget.userId}/transactions/${widget.transactionId}')
                  .update({
                "note": noteController.text.trim(),
                "amount": signedNewAmount,
              });

              // update balance
              final balSnap =
              await db.child('users/${widget.userId}/balance').get();
              final bal = int.tryParse(balSnap.value.toString()) ?? 0;
              await db
                  .child('users/${widget.userId}/balance')
                  .set(bal + delta);

              if (mounted) Navigator.pop(context);
            },
            child: const Text("Save changes"),
          ),

          const SizedBox(height: 12),

          /// DELETE BUTTON
          TextButton.icon(
            icon: const Icon(Icons.delete, color: Colors.red),
            label: const Text(
              "Delete transaction",
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text("Delete transaction?"),
                  content: const Text(
                    "This will permanently delete this transaction.\n\nThis action cannot be undone.",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () =>
                          Navigator.pop(dialogContext),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () async {
                        final txAmount = widget.oldData['amount'];

                        // remove transaction
                        await db
                            .child(
                            'users/${widget.userId}/transactions/${widget.transactionId}')
                            .remove();

                        // fix balance
                        final balSnap = await db
                            .child('users/${widget.userId}/balance')
                            .get();
                        final bal =
                            int.tryParse(balSnap.value.toString()) ?? 0;

                        await db
                            .child('users/${widget.userId}/balance')
                            .set(bal - txAmount);

                        if (mounted) {
                          Navigator.pop(dialogContext); // close dialog
                          Navigator.pop(context); // close sheet
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
