import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'main_page.dart';
import 'login_page.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  final auth = AuthService();
  Timer? _timer;

  bool checking = false;
  bool resendCooldown = false;
  int cooldownSeconds = 30;

  @override
  void initState() {
    super.initState();
    startAutoCheck();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void startAutoCheck() {
    _timer = Timer.periodic(const Duration(seconds: 5), (_) async {
      await FirebaseAuth.instance.currentUser?.reload();
      final user = FirebaseAuth.instance.currentUser;

      if (user != null && user.emailVerified) {
        _timer?.cancel();
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainPage()),
          );
        }
      }
    });
  }

  Future<void> resendEmail() async {
    if (resendCooldown) return;

    setState(() {
      resendCooldown = true;
      cooldownSeconds = 30;
    });

    await auth.resendVerification();

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (cooldownSeconds == 0) {
        timer.cancel();
        if (mounted) setState(() => resendCooldown = false);
      } else {
        if (mounted) setState(() => cooldownSeconds--);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? "";

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.mark_email_unread_outlined,
                size: 80,
                color: Colors.teal,
              ),
              const SizedBox(height: 20),

              const Text(
                "Verify your email",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              Text(
                "We sent a verification link to:\n$email",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 20),

              const Text(
                "Open your email app and click the link.\nWe’ll auto-detect once it’s verified.",
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: resendCooldown ? null : resendEmail,
                  child: resendCooldown
                      ? Text("Resend in $cooldownSeconds s")
                      : const Text("Resend verification email"),
                ),
              ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: () async {
                  setState(() => checking = true);
                  await FirebaseAuth.instance.currentUser?.reload();
                  final verified =
                      FirebaseAuth.instance.currentUser?.emailVerified ?? false;
                  setState(() => checking = false);

                  if (verified && mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const MainPage()),
                    );
                  }
                },
                child: checking
                    ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text("I’ve verified manually"),
              ),

              const SizedBox(height: 20),

              Divider(color: Colors.grey[300]),

              TextButton(
                onPressed: () async {
                  await auth.signOut();
                  if (mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                          (_) => false,
                    );
                  }
                },
                child: const Text(
                  "Wrong email? Log out",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
