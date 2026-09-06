import 'package:flutter/material.dart';

/// Lets sheet controls remain reachable with large text or an open keyboard.
class ScrollableSheetBody extends StatelessWidget {
  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;
  const ScrollableSheetBody({super.key, required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.stretch});

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
    return SingleChildScrollView(child: Column(
      crossAxisAlignment: crossAxisAlignment,
      children: children.map((child) => child is Expanded
        ? SizedBox(height: 240 * MediaQuery.textScalerOf(context).scale(1), child: child.child)
        : child).toList()));
  });
}
