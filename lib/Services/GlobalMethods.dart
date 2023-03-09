import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';

// Class that contains static methods to be used by any object.
class GlobalMethods {
  // Method that can be used from anywhere to show Snackbar using Flushbar package.
  // if it's an Exception make the snackbar red.
  static void snackBarError(String msg, BuildContext context,
      {bool isException = false}) {
    Flushbar(
      icon: Icon(
        Icons.error,
        color: Colors.white,
      ),
      duration: Duration(seconds: 3),
      message: msg,
      flushbarPosition: FlushbarPosition.TOP,
      flushbarStyle: FlushbarStyle.FLOATING,
      backgroundColor: isException == false ? Colors.black : Colors.red,
      borderRadius: BorderRadius.circular(20),
      margin: EdgeInsets.all(20),
      isDismissible: true,
    )..show(context);
  }
}
