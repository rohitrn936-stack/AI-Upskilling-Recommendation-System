import 'package:flutter/material';

SnackBar successSnackbar({
  required String message,
  Duration duration = const Duration(seconds: 3),
}) {
  return SnackBar(
    content: Row(
      children: [
        const Icon(Icons.check_circle, color: Colors.white),
        const SizedBox(width: 8),
        Text(message),
      ],
    ),
    backgroundColor: Color(0xFF10B981),
    behavior: SnackBarBehavior.floating,
    duration: duration,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    margin: const EdgeInsets.all(12),
  );
}

SnackBar errorSnackbar({
  required String message,
  Duration duration = const Duration(seconds: 3),
}) {
  return SnackBar(
    content: Row(
      children: [
        const Icon(Icons.error, color: Colors.white),
        const SizedBox(width: 8),
        Text(message),
      ],
    ),
    backgroundColor: Color(0xFFF87171),
    behavior: SnackBarBehavior.floating,
    duration: duration,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    margin: const EdgeInsets.all(12),
  );
}

SnackBar infoSnackbar({
  required String message,
  Duration duration = const Duration(seconds: 2),
}) {
  return SnackBar(
    content: Row(
      children: [
        const Icon(Icons.info_outline, color: Colors.white),
        const SizedBox(width: 8),
        Text(message),
      ],
    ),
    backgroundColor: Color(0xFF3B82F6),
    behavior: SnackBarBehavior.floating,
    duration: duration,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    margin: const EdgeInsets.all(12),
  );
}

void showSnackbar(BuildContext context, SnackBar snackBar) {
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}