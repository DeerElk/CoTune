import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FolderTile extends StatelessWidget {
  final String name;
  final String? subtitle;
  final VoidCallback? onTap;

  const FolderTile({super.key, required this.name, this.subtitle, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final titleStyle = GoogleFonts.manrope(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: theme.colorScheme.onBackground,
    );
    final subtitleStyle = GoogleFonts.inter(
      fontSize: 13,
      color: theme.textTheme.bodyMedium?.color,
    );

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      title: Text(name, style: titleStyle),
      subtitle: subtitle != null ? Text(subtitle!, style: subtitleStyle) : null,
      trailing: Icon(Icons.chevron_right, color: theme.iconTheme.color),
      onTap: onTap,
    );
  }
}
