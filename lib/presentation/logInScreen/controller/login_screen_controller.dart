import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/pref_utils.dart';
import '../../../services/supabase_services.dart';
import '../../../widgets/custom_toast.dart';
import '../../AdminDashboardScreen/admin_dashboard_screen.dart';
import '../../dashboardScreen/dashboard_Screen.dart';

class LoginScreenController extends GetxController {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  final formKeyUser = GlobalKey<FormState>();
  final formKeyAdmin = GlobalKey<FormState>();

  bool isHidden = true;
  bool isLoading = false;
  bool isAdmin = false;

  void togglePassword() {
    isHidden = !isHidden;
    update();
  }

  Future<void> login() async {
    isLoading = true;
    update();

    try {
      final result = await SupabaseServices.signIn(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      print("login result -- $result");

      if (result['success'] == true) {
        final role = result['role'];

        if (isAdmin && role == "admin") {
          CustomToast.showToast(
            "Admin Login successfully",
            color: Colors.green,
          );

          // Save login state
          await PrefUtils.setLoggedIn(true);
          await PrefUtils.setUserRole("admin");

          Get.offAll(() => const AdminDashboardScreen());
        } else if (!isAdmin && role == "user") {
          // CustomToast.showToast(
          //   "User Login successfully",
          //   color: Colors.green,
          // );

          // Save login state
          await PrefUtils.setLoggedIn(true);
          await PrefUtils.setUserRole("user");

          Get.offAll(() => const DashBoardScreen());
        } else {
          // Role mismatch (wrong button pressed)
          await SupabaseServices.signOut();
          CustomToast.showToast(
            "Access Denied,\nThis account doesn't have permission for this login.",
            color: Colors.red,
          );
        }
      } else {
        CustomToast.showToast(
          result['error'] ?? "Login failed",
          color: Colors.red,
        );
      }
    } catch (e) {
      CustomToast.showToast(
        "Login error: ${e.toString()}",
        color: Colors.red,
      );
    } finally {
      isLoading = false;
      update();
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
