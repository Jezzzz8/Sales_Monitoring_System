// lib/widgets/top_loading_indicator.dart - SIMPLER VERSION
import 'package:flutter/material.dart';

class TopLoadingIndicator extends StatefulWidget {
  final Color? color;
  const TopLoadingIndicator({super.key, this.color});

  @override
  State<TopLoadingIndicator> createState() => _TopLoadingIndicatorState();
}

class _TopLoadingIndicatorState extends State<TopLoadingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      color: Colors.transparent,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.rotate(
                angle: _controller.value * 2 * 3.14159,
                child: child,
              );
            },
            child: Icon(
              Icons.refresh,
              size: 20,
              color: widget.color ?? Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }
}