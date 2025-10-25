import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CustomToast {
  static Color defaultColor = Colors.red;

  static void showToast(String title, {Color? color}) {
    Fluttertoast.showToast(
      msg: title,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.CENTER,
      timeInSecForIosWeb: 1,
      backgroundColor: color ?? defaultColor,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }
}
