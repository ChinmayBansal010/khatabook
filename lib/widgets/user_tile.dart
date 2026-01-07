import 'package:flutter/material.dart';

class UserTile extends StatelessWidget {
  final String name;
  final int balance;
  final bool isPinned;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const UserTile({
    super.key,
    required this.name,
    required this.balance,
    required this.isPinned,
    this.onTap,
    this.onLongPress
  });

  @override
  Widget build(BuildContext context) {
    final bool owesYou = balance >= 0;
    final Color accentColor = owesYou ? Colors.red : Colors.green;

    debugPrint(isPinned.toString());

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: CircleAvatar(
              radius: 22,
              backgroundColor: accentColor.withValues(alpha: 0.15),
              child: Text(
                name[0].toUpperCase(),
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            title: Row(
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (isPinned)
                  Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      "PINNED",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Text(
              owesYou ? "They owe you" : "You owe them",
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "₹${balance.abs()}",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 2),
                Icon(
                  owesYou ? Icons.arrow_downward : Icons.arrow_upward,
                  size: 16,
                  color: accentColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
