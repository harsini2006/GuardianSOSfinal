import 'package:flutter/material.dart';

enum ButtonType { primary, secondary, outline, danger }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final ButtonType type;
  final IconData? icon;
  final bool isLoading;
  final double? width;

  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.type = ButtonType.primary,
    this.icon,
    this.isLoading = false,
    this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Color getBgColor() {
      switch (type) {
        case ButtonType.primary:
          return theme.colorScheme.primary;
        case ButtonType.secondary:
          return theme.colorScheme.secondary;
        case ButtonType.danger:
          return theme.colorScheme.error;
        case ButtonType.outline:
          return Colors.transparent;
      }
    }

    Color getFgColor() {
      switch (type) {
        case ButtonType.primary:
          return theme.colorScheme.onPrimary;
        case ButtonType.secondary:
          return theme.colorScheme.onSecondary;
        case ButtonType.danger:
          return theme.colorScheme.onError;
        case ButtonType.outline:
          return theme.brightness == Brightness.light
              ? theme.colorScheme.primary
              : Colors.white;
      }
    }

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: getBgColor(),
      foregroundColor: getFgColor(),
      side: type == ButtonType.outline
          ? BorderSide(
              color: theme.brightness == Brightness.light
                  ? theme.colorScheme.primary.withOpacity(0.3)
                  : Colors.white.withOpacity(0.3),
              width: 1.5,
            )
          : BorderSide.none,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );

    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null && !isLoading) ...[
          Icon(icon, size: 20),
          const SizedBox(width: 8),
        ],
        if (isLoading)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(getFgColor()),
            ),
          )
        else
          Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: getFgColor(),
            ),
          ),
      ],
    );

    return SizedBox(
      width: width ?? double.infinity,
      height: 52,
      child: ElevatedButton(
        style: buttonStyle,
        onPressed: isLoading ? null : onPressed,
        child: content,
      ),
    );
  }
}
