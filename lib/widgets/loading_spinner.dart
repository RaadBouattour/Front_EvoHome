import 'package:flutter/material.dart';

class LoadingSpinner extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final Color color;
  final EdgeInsetsGeometry padding;

  const LoadingSpinner({
    super.key,
    this.size = 32.0,
    this.strokeWidth = 3.0,
    this.color = Colors.grey,
    this.padding = const EdgeInsets.only(top: 24.0),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: strokeWidth,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    );
  }
}
