import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class ThumbsAnimation extends StatefulWidget {
  const ThumbsAnimation({
    Key? key,
    required this.isThumbsUp
  }) : super(key: key);

  final bool isThumbsUp;

  @override
  State createState() => _ThumbsAnimationState();
}

class _ThumbsAnimationState extends State<ThumbsAnimation> {

  late RiveAnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SimpleAnimation('press');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: RiveAnimation.asset(
          'assets/thumbs.riv',
          artboard: widget.isThumbsUp ? 'good' : 'bad',
          controllers: [_controller],
        ),
      ),
    );
  }
}
