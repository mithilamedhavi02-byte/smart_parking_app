import 'package:flutter/material.dart' as material; // material කියලා prefix එකක් දුන්නා
import 'package:flutter/widgets.dart';

class MyAppIcon extends StatelessWidget {
  final IconData iconData;
  final double? size;
  final Color? color;

  const MyAppIcon({
    super.key,
    required this.iconData,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    // නිකන්ම 'Icon' පාවිච්චි කරන්නේ නැතුව 'material.Icon' කියලාම කියමු
    return material.Icon(
      iconData,
      size: size ?? 24.0,
      color: color ?? material.Colors.white,
    );
  }
}