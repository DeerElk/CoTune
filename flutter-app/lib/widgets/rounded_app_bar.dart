import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

class RoundedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final bool centerTitle;
  final double toolbarHeight;
  final Color? backgroundColor;
  final IconThemeData? iconTheme;
  final double borderRadius;

  const RoundedAppBar({
    super.key,
    this.title,
    this.actions,
    this.bottom,
    this.centerTitle = false,
    this.toolbarHeight = 64,
    this.backgroundColor,
    this.iconTheme,
    this.borderRadius = 18,
  });

  @override
  Size get preferredSize {
    final bottomHeight = bottom?.preferredSize.height ?? 0;
    return Size.fromHeight(toolbarHeight + bottomHeight);
  }

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? CotuneTheme.highlight;
    return AppBar(
      backgroundColor: bg,
      elevation: 0,
      toolbarHeight: toolbarHeight,
      centerTitle: centerTitle,
      title: title,
      actions: actions,
      bottom: bottom,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(borderRadius),
        ),
      ),
      iconTheme:
          iconTheme ?? const IconThemeData(color: CotuneTheme.headerTextColor),
      titleTextStyle: GoogleFonts.manrope(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: CotuneTheme.headerTextColor,
      ),
    );
  }
}
