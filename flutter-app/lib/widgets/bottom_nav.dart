import 'package:flutter/material.dart';
import '../theme.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.colorScheme.surface;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),

      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 44,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _NavButton(
                icon: Icons.search,
                index: 0,
                currentIndex: currentIndex,
                onTap: onTap,
                tooltip: 'Поиск',
              ),
              _NavButton(
                icon: Icons.music_note,
                index: 1,
                currentIndex: currentIndex,
                onTap: onTap,
                tooltip: 'Музыка',
              ),
              _NavButton(
                icon: Icons.person,
                index: 2,
                currentIndex: currentIndex,
                onTap: onTap,
                tooltip: 'Профиль',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final String tooltip;

  const _NavButton({
    required this.icon,
    required this.index,
    required this.currentIndex,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = index == currentIndex;

    final bg = active
        ? CotuneTheme.highlight.withOpacity(0.12)
        : Colors.transparent;

    final iconColor = active
        ? CotuneTheme.highlight
        : theme.iconTheme.color?.withOpacity(0.85);

    return Semantics(
      button: true,
      label: tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => onTap(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Icon(
                icon,
                color: iconColor,
                size: 26,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

