import 'package:flutter/material.dart';

showSnackBar(
  BuildContext context,
  String errorMessage, {
  bool isSuccess = false,
}) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();

  final snackBar = SnackBar(
    backgroundColor: Colors.white,
    margin: const EdgeInsets.all(24.0),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20.0),
    ),
    content: Text(
      errorMessage,
      style: TextStyle(
        fontSize: 16,
        color: isSuccess ? Colors.green : Colors.red,
      ),
    ),
  );

  return ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
