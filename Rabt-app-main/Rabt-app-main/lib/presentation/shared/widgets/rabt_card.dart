import 'package:flutter/material.dart';
import '../../../core/constants/design_constants.dart';

class RabtCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? elevation;
  final Color? backgroundColor;

  const RabtCard({
    super.key,
    required this.child,
    this.padding,
    this.elevation,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation ?? 1,
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RabtDesignConstants.radiusMd),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(RabtDesignConstants.spaceLg),
        child: child,
      ),
    );
  }
}
