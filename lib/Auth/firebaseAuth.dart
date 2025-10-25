// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:get/get_core/src/get_main.dart';
//
// import '../presentation/dashboardScreen/dashboard_Screen.dart';
// import '../widgets/custom_toast.dart';
//
// class FirebaseServices {
//   static final FirebaseAuth auth = FirebaseAuth.instance;
//
//   // Sign Up
//   static Future<User?> signUp(String email, String password) async {
//     try {
//       UserCredential userCredential = await auth.createUserWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//       // CustomToast.showToast(
//       //     "Sign up successfully",
//       //     color: Colors.green
//       // );
//
//       return userCredential.user;
//     } on FirebaseAuthException catch (e) {
//       CustomToast.showToast(
//           "${e.message}",
//           color: Colors.red
//       );
//
//       print('Signup Error: ${e.message}');
//       return null;
//     }
//   }
//
//   // Sign In
//   static Future<User?> signIn(String email, String password) async {
//     print("login  email==========$email");
//     print("login  password==========$password");
//     try {
//       UserCredential userCredential = await auth.signInWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//       print('Signup ---------------Error: $userCredential');
//
//       // CustomToast.showToast(
//       //   "Login successfully",
//       //   color: Colors.green
//       // );
//       return userCredential.user;
//     } on FirebaseAuthException catch (e) {
//       CustomToast.showToast(
//           "${e.message}",
//           color: Colors.red
//       );
//
//       print('SignIn Error: ${e.message}');
//       return null;
//     }
//   }
//
//   // Sign Out
//   static Future<void> signOut() async {
//     await auth.signOut();
//   }
// }
