import 'package:flutter/material.dart';
import 'dart:async';
import 'splash_screen_1.dart';

class AppOpeningFlash extends StatefulWidget {
  const AppOpeningFlash({Key? key}) : super(key: key);

  @override
  State<AppOpeningFlash> createState() => _AppOpeningFlashState();
}

class _AppOpeningFlashState extends State<AppOpeningFlash> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 1), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SplashScreen1()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.pink.shade50,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '🧸',
                  style: TextStyle(fontSize: 80),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'KIDS SHOP',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.pink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
