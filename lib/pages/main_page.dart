import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';

import 'home_page.dart';
import 'group_page.dart';
import 'package:pocketkhata/dialogs/create_group_dialog.dart';

import 'login_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int index = 0;
  late final PageController _pageController;

  final ScrollController usersScrollController = ScrollController();
  final uid = FirebaseAuth.instance.currentUser!.uid;
  late final DatabaseReference groupRef = FirebaseDatabase.instance.ref('$uid/groups');

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    usersScrollController.dispose();
    super.dispose();
  }

  void onTabSelected(int i) {
    HapticFeedback.selectionClick();

    if (i == 0 && index == 0) {
      usersScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      return;
    }

    setState(() => index = i);
    _pageController.animateToPage(
      i,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("PocketKhata"),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'logout') {
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Logout?"),
                    content: const Text("You will need to login again."),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Cancel"),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("Logout"),
                      ),
                    ],
                  ),
                );

                if (shouldLogout != true) return;

                await FirebaseAuth.instance.signOut();

                if (!context.mounted) return;

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                      (_) => false,
                );
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text("Logout"),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (i) {
          setState(() => index = i);
          HapticFeedback.selectionClick();
        },
        children: [
          HomePage(scrollController: usersScrollController),
          const GroupPage(),
        ],
      ),
      bottomNavigationBar: StreamBuilder<DatabaseEvent>(
        stream: groupRef.onValue,
        builder: (context, snapshot) {
          int groupCount = 0;

          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            final map =
            Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
            groupCount = map.length;
          }

          return NavigationBar(
            selectedIndex: index,
            height: 65,
            elevation: 8,
            indicatorColor: Colors.teal.withValues(alpha: 0.15),
            onDestinationSelected: onTabSelected,
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: "Users",
              ),

              NavigationDestination(
                icon: GestureDetector(
                  onLongPress: () {
                    showDialog(
                      context: context,
                      builder: (_) => const CreateGroupDialog(),
                    );
                  },
                  child: Badge(
                    isLabelVisible: groupCount > 0,
                    label: Text(groupCount.toString()),
                    child: const Icon(Icons.group_outlined),
                  ),
                ),
                selectedIcon: const Icon(Icons.group),
                label: "Groups",
              ),
            ],
          );
        },
      ),
    );
  }
}
