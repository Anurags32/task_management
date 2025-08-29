import 'package:flutter/material.dart';
import 'package:task_management/theme.dart' show AppTheme;

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/onboarding');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // White background
          Container(color: Colors.white),

          // Blurry colored blobs
          Positioned(
            top: 100,
            left: -60,
            child: _buildBlob(AppTheme.blobGreen, 180),
          ),
          Positioned(
            top: 50,
            right: -80,
            child: _buildBlob(AppTheme.blobYellow, 200),
          ),
          Positioned(
            bottom: 120,
            left: -70,
            child: _buildBlob(AppTheme.blobBlue, 220),
          ),
          Positioned(
            bottom: 80,
            right: -60,
            child: _buildBlob(AppTheme.blobPurple, 180),
          ),

          // Centered Logo Text
          const Center(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: "L",
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  TextSpan(
                    text: "O",
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6C4CE2), // purple
                    ),
                  ),
                  TextSpan(
                    text: "G",
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  TextSpan(
                    text: "O",
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6C4CE2), // purple
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Helper widget for soft blur circles
  Widget _buildBlob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        // color: color.withOpacity(0.4),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 120,
            spreadRadius: 60,
          ),
        ],
      ),
    );
  }
}
