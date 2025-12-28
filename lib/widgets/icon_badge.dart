import 'package:flutter/material.dart';

class IconBadge extends StatelessWidget {
  final IconData icon;
  final double? size;
  final Color? color;

  const IconBadge({
    super.key,
    required this.icon,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Icon(
          icon,
          size: size,
          color: color,
        ),
        Positioned(
          right: 0.0,
          top: 0.0,
          child: Container(
            padding: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(6),
            ),
            height: 12.0,
            width: 12.0,
            child: Container(
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: Colors.red[300],
                borderRadius: BorderRadius.circular(6),
              ),
              height: 7.0,
              width: 7.0,
            ),
          ),
        ),
      ],
    );
  }
}
