import 'package:flutter/material.dart';

class SimpleLoadingDialog {
  static bool _isShowing = false;
  static BuildContext? _dialogContext;

  static void show(BuildContext context, {String message = 'Loading...'}) {
    if (_isShowing) return;
    
    _isShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        _dialogContext = context;
        return _LoadingDialogContent(message: message);
      },
    ).then((_) {
      _isShowing = false;
      _dialogContext = null;
    });
  }

  static void hide(BuildContext context) {
    if (_isShowing && _dialogContext != null && Navigator.of(_dialogContext!, rootNavigator: true).canPop()) {
      Navigator.of(_dialogContext!, rootNavigator: true).pop();
      _isShowing = false;
      _dialogContext = null;
    } else if (_isShowing) {
      // Try with the provided context as fallback
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      _isShowing = false;
      _dialogContext = null;
    }
  }
}

class _LoadingDialogContent extends StatelessWidget {
  final String message;

  const _LoadingDialogContent({required this.message});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.deepOrange,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Please wait...',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}