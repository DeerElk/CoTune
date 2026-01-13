import 'package:flutter/material.dart';

class ChipsRow extends StatelessWidget {
  final List<Widget> chips;
  final double leftPadding;

  const ChipsRow({super.key, required this.chips, this.leftPadding = 12});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: leftPadding, right: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: chips.map((w) => Padding(
            padding: const EdgeInsets.only(right: 8), child: w),
          ).toList(),
        ),
      ),
    );
  }
}
