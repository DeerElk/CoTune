import 'package:flutter/material.dart';

class ChipsRow extends StatelessWidget {
  final List<Widget> chips;
  final double viewportInset;
  final double chipSpacing;

  const ChipsRow({
    super.key,
    required this.chips,
    this.viewportInset = 12,
    this.chipSpacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: viewportInset),
                ...chips.map(
                  (w) => Padding(
                    padding: EdgeInsets.only(right: chipSpacing),
                    child: w,
                  ),
                ),
                SizedBox(width: viewportInset),
              ],
            ),
          ),
        );
      },
    );
  }
}
