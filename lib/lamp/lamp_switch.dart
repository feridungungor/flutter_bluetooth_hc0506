import 'package:flutter/material.dart';

final blubOnColor = const Color(0xFFFFE12C);
final blubOffColor = const Color(0xFFc1c1c1);

class LampSwitch extends StatelessWidget {
  final Function onTap;
  final bool isSwitchOn;
  final Color toggleOnColor, toggleOffColor,color;
  final double screenWidth, screenHeight;
  final Duration animationDuration;

  const LampSwitch({
    Key key,
    this.onTap,
    this.isSwitchOn,
    this.screenWidth,
    this.screenHeight,
    this.animationDuration,
    this.toggleOnColor,
    this.toggleOffColor,
    this.color
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: screenHeight * 0.31,
      width: 30,
      left: screenWidth * 0.5 - 15,
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          children: <Widget>[
            AnimatedContainer(
              duration: animationDuration,
              width: 30,
              height: 70,
              decoration: BoxDecoration(
                color: isSwitchOn ? blubOnColor : blubOffColor,
                borderRadius: BorderRadius.circular(15)
              ),
            ),
            AnimatedPositioned(
              duration: animationDuration,
              left: 0,
              right: 0,
              top: isSwitchOn ? 42 : 4,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
