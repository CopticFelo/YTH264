import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';

class GlobalMethods {
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
