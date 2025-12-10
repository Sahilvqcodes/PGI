import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/pref_utils.dart';
import '../../../services/supabase_services.dart';
import '../../../widgets/custom_toast.dart';
import '../../AdminDashboardScreen/admin_dashboard_screen.dart';
import '../../dashboardScreen/dashboard_Screen.dart';

class SignUpScreenController extends GetxController {
  // Controllers for form inputs
  TextEditingController signUpEmailController = TextEditingController();
  TextEditingController signUpPasswordController = TextEditingController();
  TextEditingController signUpNameController = TextEditingController();

  // Separate keys for user & admin forms
  final signUpUserFormKey = GlobalKey<FormState>();
  final signUpAdminFormKey = GlobalKey<FormState>();

  bool isHidden = true;
  bool isLoading = false;

  void togglePassword() {
    isHidden = !isHidden;
    update();
  }





  Future<void> signUp({required bool isAdmin}) async {
    try {
      isLoading = true;
      update();

      final result = await SupabaseServices.signUp(
        email: signUpEmailController.text.trim(),
        password: signUpPasswordController.text.trim(),
        name: signUpNameController.text.trim(),
        role: isAdmin ? "admin" : "user",
      );

      isLoading = false;
      update();

      if (result['success'] == true) {
        // Save login state
        await PrefUtils.setLoggedIn(true);
        await PrefUtils.setUserRole(result['role']);

        // Navigate based on role
        if (isAdmin) {
          CustomToast.showToast(
            "Sign up successfully",
            color: Colors.green,
          );
          Get.offAll(() => const AdminDashboardScreen());
        } else {
          CustomToast.showToast(
            "Sign up successfully",
            color: Colors.green,
          );
          Get.offAll(() => const DashBoardScreen());
        }
      } else {
        CustomToast.showToast(
          result['error'] ?? "Signup failed",
        );
      }
    } catch (e) {
      isLoading = false;
      update();
      CustomToast.showToast(
        "Signup error: ${e.toString()}",
      );
    }
  }


  @override
  void onClose() {
    signUpEmailController.dispose();
    signUpPasswordController.dispose();
    signUpNameController.dispose();
    super.onClose();
  }
}
