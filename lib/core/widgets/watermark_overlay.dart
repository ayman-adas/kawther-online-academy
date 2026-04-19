import 'package:flutter/material.dart';
import 'dart:math' as math;

class WatermarkOverlay extends StatelessWidget {
  final String text;
  final double opacity;

  const WatermarkOverlay({
    super.key,
    this.text = 'CONFIDENTIAL',
    this.opacity = 0.15,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          // LayoutBuilder to fill the screen with the pattern
          LayoutBuilder(builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                children: List.generate(
                  (constraints.maxHeight / 100).ceil() + 2,
                  (index) => SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        (constraints.maxWidth / 150).ceil() + 1,
                        (rowInnerIndex) => Transform.rotate(
                          angle: -math.pi / 4,
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Text(
                              text,
                              style: TextStyle(
                                color: Colors.grey.withOpacity(opacity),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
