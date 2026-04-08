import 'dart:ui';

import 'package:flutter/material.dart';

class PremiumBackground extends StatelessWidget {
  const PremiumBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
    children: [
      Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.5, -0.15),
            radius: 1,
            colors: [
              Color.fromARGB(45, 68, 0, 255),
              Color.fromARGB(0, 0, 0, 0),
            ],
            stops: [0.0, 1.0],
          ),
        ),
        width: double.infinity,
        height: double.infinity,
      ),
      Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.2, -0.5),
            radius: 1,
            colors: [
              Color.fromARGB(45, 0, 51, 255),
              Color.fromARGB(0, 0, 0, 0),
            ],
            stops: [0.0, 1.0],
          ),
        ),
        width: double.infinity,
        height: double.infinity,
      ),
      Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.4, 0.2),
            radius: 1,
            colors: [
              Color.fromARGB(45, 255, 0, 0),
              Color.fromARGB(0, 0, 0, 0),
            ],
            stops: [0.0, 1.0],
          ),
        ),
        width: double.infinity,
        height: double.infinity,
      ),
      Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.45, 0.6),
            radius: 1,
            colors: [
              Color.fromARGB(45, 119, 0, 255),
              Color.fromARGB(0, 0, 0, 0),
            ],
            stops: [0.0, 1.0],
          ),
        ),
        width: double.infinity,
        height: double.infinity,
      ),
      Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.6, -0.6),
            radius: 1,
            colors: [
              Color.fromARGB(30, 255, 0, 0),
              Color.fromARGB(0, 0, 0, 0),
            ],
            stops: [0.0, 1.0],
          ),
        ),
        width: double.infinity,
        height: double.infinity,
      ),
      Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.6, 0.6),
            radius: 1,
            colors: [
              Color.fromARGB(30, 0, 51, 255),
              Color.fromARGB(0, 0, 0, 0),
            ],
            stops: [0.0, 1.0],
          ),
        ),
        width: double.infinity,
        height: double.infinity,
      ),

      // Noise
      Positioned.fill(
        child: IgnorePointer(
          child: Opacity(
            opacity: 0.01,
            child: Image.asset(
              "assets/images/noise.png",
              fit: BoxFit.cover,
              repeat: ImageRepeat.repeat,
            ),
          ),
        ),
      ),

      // Blur
      Positioned.fill(
        child: Stack(
          children: [
            ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(
                  color: Colors.grey.shade500.withAlpha(5),
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
  }
}