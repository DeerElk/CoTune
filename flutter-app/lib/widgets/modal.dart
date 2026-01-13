import 'package:flutter/material.dart';
import '../theme.dart';

Future<T?> showCotuneModal<T>(
    BuildContext context, {
      required List<Widget> Function(BuildContext) builder,
      String? title,
      bool isDismissible = true,
      bool enableDrag = true,
      double topCornerRadius = 16.0,
      double? maxHeightFraction,
    }) {
  final modalTheme = Theme.of(context).extension<CotuneModalTheme>()!;

  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    barrierColor: modalTheme.barrier,
    builder: (ctx) {
      final theme = Theme.of(ctx);

      final inputTheme = theme.copyWith(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: modalTheme.inputFill,
          hintStyle: TextStyle(color: modalTheme.hint),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: modalTheme.inputBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: CotuneTheme.highlight),
          ),
        ),
      );

      Widget content = Theme(
        data: inputTheme,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: modalTheme.handle,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 16),

            if (title != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge,
                ),
              ),

            const SizedBox(height: 24),
            ...builder(ctx),
            SizedBox(height: MediaQuery.of(ctx).viewPadding.bottom + 12),
          ],
        ),
      );

      Widget sheet = Container(
        decoration: BoxDecoration(
          color: modalTheme.background,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(topCornerRadius),
          ),
          boxShadow: [
            BoxShadow(
              color: modalTheme.shadow,
              blurRadius: 24,
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: content,
          ),
        ),
      );

      if (maxHeightFraction != null) {
        sheet = FractionallySizedBox(
          heightFactor: maxHeightFraction.clamp(0.0, 1.0),
          alignment: Alignment.bottomCenter,
          child: sheet,
        );
      }

      return sheet;
    },
  );
}

class CotuneModalActions extends StatelessWidget {
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;
  final String cancelLabel;
  final String confirmLabel;
  final bool destructiveConfirm;

  const CotuneModalActions({
    super.key,
    this.onCancel,
    this.onConfirm,
    this.cancelLabel = 'Отмена',
    this.confirmLabel = 'Сохранить',
    this.destructiveConfirm = false,
  });

  @override
  Widget build(BuildContext context) {
    final modalTheme = Theme.of(context).extension<CotuneModalTheme>()!;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: modalTheme.cancelButtonBg,
                foregroundColor: theme.colorScheme.onSurface,
              ),
              onPressed: onCancel ?? () => Navigator.of(context).pop(),
              child: Text(cancelLabel),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: destructiveConfirm
                    ? theme.colorScheme.error
                    : CotuneTheme.highlight,
                foregroundColor: modalTheme.confirmText,
              ),
              onPressed: onConfirm,
              child: Text(confirmLabel),
            ),
          ),
        ],
      ),
    );
  }
}
