import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/group_service.dart';
import '../widgets/edit_transaction_sheet.dart';

class UserPage extends StatefulWidget{
  final String userId;
  const UserPage({super.key, required this.userId});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> with SingleTickerProviderStateMixin {
  late DatabaseReference userRef;
  final TextEditingController noteController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  final FocusNode noteFocus = FocusNode();
  final FocusNode amountFocus = FocusNode();

  late AnimationController shakeController;
  late Animation<double> shakeAnimation;

  bool isAmountValid = false;

  @override
  void initState() {
    super.initState();
    shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10, end: -10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10, end: 0), weight: 1),
    ]).animate(shakeController);

    final uid = FirebaseAuth.instance.currentUser!.uid;
    userRef = FirebaseDatabase.instance.ref('$uid/users/${widget.userId}');
  }

  @override
  void dispose() {
    shakeController.dispose();
    noteFocus.dispose();
    amountFocus.dispose();
    super.dispose();
  }

  Future<void> addTransaction(bool isCredit) async {
    if (!isAmountValid) {
      shakeController.forward(from: 0);
      return;
    }

    if (noteController.text.isEmpty) return;

    int amount = int.tryParse(amountController.text) ?? 0;
    if (amount <= 0) return;

    if (isCredit) amount = -amount;

    final transRef = userRef.child('transactions').push();

    await transRef.set({
      "note": noteController.text,
      "amount": amount,
      "time": DateTime.now().toIso8601String(),
    });

    final balSnap = await userRef.child('balance').get();
    final currentBal = int.tryParse(balSnap.value.toString()) ?? 0;
    final newBalance = currentBal + amount;
    await userRef.child('balance').set(newBalance);
    final groupSnap = await userRef.child('groupId').get();
    if (groupSnap.value != null) {
      final groupId = groupSnap.value.toString();
      await updateGroupTotalBalance(groupId);
    }

    noteController.clear();
    amountController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<DatabaseEvent>(
        stream: userRef.onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final data =
          Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);

          final name = data['name'];
          final balance = data['balance'] ?? 0;
          Map<String, dynamic> transactions = {};

          final rawTransactions = data['transactions'];

          if (rawTransactions is Map) {
            transactions = Map<String, dynamic>.from(rawTransactions);
          } else if (rawTransactions is List) {
            for (int i = 0; i < rawTransactions.length; i++) {
              if (rawTransactions[i] != null) {
                transactions[i.toString()] =
                Map<String, dynamic>.from(rawTransactions[i]);
              }
            }
          }
          final transList = transactions.entries.toList()
            ..sort((a, b) => b.key.compareTo(a.key));

          return SafeArea(
            child: Column(
              children: [
                AppBar(title: Text(name)),
                Card(
                  margin: const EdgeInsets.all(12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 6,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: balance >= 0
                            ? [Colors.red.shade300, Colors.red.shade600]
                            : [Colors.green.shade300, Colors.green.shade600],
                      ),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(Icons.account_balance_wallet, color: Colors.white, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          "₹${balance.abs()}",
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          balance >= 0 ? "They owe you" : "You owe them",
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    reverse: true,
                    padding: const EdgeInsets.all(8),
                    children: transList.map((entry) {
                      final tx = entry.value;
                      final isCredit = tx['amount'] < 0;
                      final time = DateFormat('dd MMM yyyy hh:mm a')
                          .format(DateTime.parse(tx['time']));

                      return GestureDetector(
                        onLongPress: () {
                          HapticFeedback.mediumImpact();
                          showModalBottomSheet(
                            context: context,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                            ),
                            builder: (_) => EditTransactionSheet(
                              userId: widget.userId,
                              transactionId: entry.key,
                              oldData: Map<String, dynamic>.from(entry.value),
                            ),
                          );
                        },
                        child: Align(
                          alignment: isCredit
                              ? Alignment.centerLeft
                              : Alignment.centerRight,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isCredit
                                  ? Colors.green[100]
                                  : Colors.red[100],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "₹${tx['amount'].abs()}",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: isCredit ? Colors.green[800] : Colors.red[800],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  tx['note'],
                                  style: const TextStyle(fontSize: 16),
                                ),
                                Text(
                                  time,
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                        
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  child: Column(
                    children: [
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              TextField(
                                controller: noteController,
                                focusNode: noteFocus,
                                textInputAction: TextInputAction.next,
                                onSubmitted: (_) {
                                  FocusScope.of(context).requestFocus(amountFocus);
                                },
                                decoration: const InputDecoration(
                                  labelText: "Note",
                                  hintText: "Dinner, Rent, Petrol...",
                                  prefixIcon: Icon(Icons.edit_note),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              AnimatedBuilder(
                                animation: shakeAnimation,
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: Offset(shakeAnimation.value, 0),
                                    child: child,
                                  );
                                },
                                child: TextField(
                                  controller: amountController,
                                  focusNode: amountFocus,
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    setState(() {
                                      isAmountValid = int.tryParse(value) != null && int.parse(value) > 0;
                                    });
                                  },
                                  decoration: const InputDecoration(
                                    labelText: "Amount",
                                    prefixText: "₹ ",
                                    prefixIcon: Icon(Icons.currency_rupee),
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.call_received, color: Colors.black),
                              label: const Text(
                                "Taken",
                                style: TextStyle(
                                    color: Colors.black ,
                                    fontWeight: FontWeight.bold
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: isAmountValid ? () => addTransaction(true) : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.call_made, color: Colors.black,),
                              label: const Text(
                                "Given",
                                style: TextStyle(
                                    color: Colors.black ,
                                    fontWeight: FontWeight.bold
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: isAmountValid ? () => addTransaction(false) : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}