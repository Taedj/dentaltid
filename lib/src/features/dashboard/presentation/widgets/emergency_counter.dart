import 'package:flutter/material.dart';

class EmergencyCounter extends StatefulWidget {
  const EmergencyCounter({super.key, required this.emergencyCount});

  final int emergencyCount;

  @override
  State<EmergencyCounter> createState() => _EmergencyCounterState();
}

class _EmergencyCounterState extends State<EmergencyCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    if (widget.emergencyCount > 0) {
      _animationController.repeat(reverse: true);
    }

    _colorAnimation = ColorTween(begin: Colors.white, end: Colors.red).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant EmergencyCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.emergencyCount > 0 && !_animationController.isAnimating) {
      _animationController.repeat(reverse: true);
    } else if (widget.emergencyCount == 0 && _animationController.isAnimating) {
      _animationController.stop();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        return Text(
          'Emergency: ${widget.emergencyCount}',
          style: TextStyle(
            color: widget.emergencyCount > 0
                ? _colorAnimation.value
                : Colors.white,
            fontSize: 14,
            fontWeight: widget.emergencyCount > 0
                ? FontWeight.bold
                : FontWeight.normal,
          ),
          textAlign: TextAlign.left,
        );
      },
    );
  }
}
