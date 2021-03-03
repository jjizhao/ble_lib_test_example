import 'package:flutter/material.dart';

class MInkWell extends StatelessWidget {
  final Widget child;
  final Function onPressed;

  MInkWell({@required this.child, this.onPressed});

  bool get disabled => this.onPressed == null;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.all(
          Radius.circular(4.0),
        ),
        // highlightColor: const Color(0xFF00AAFF),
        // splashColor: const Color(0xFF00AAFF),
        onTap: disabled ? null : onPressed,
        child: child,
      ),
    );
  }
}
