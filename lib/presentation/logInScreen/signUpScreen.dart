import 'package:chandigarh/presentation/logInScreen/logIn_screen.dart';
import 'package:chandigarh/widgets/custom_loading_container.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/image_constants.dart';
import 'controller/signUp_screen_controller.dart';
import 'package:chandigarh/widgets/custom_text_form_field.dart';
import 'package:chandigarh/widgets/custom_elevated_button.dart';


class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SignUpScreenController());

    return GetBuilder<SignUpScreenController>(
      builder: (controller) {
        return Scaffold(
          backgroundColor: const Color(0xFF0D2C54),
          body: Column(
            children: [
              // Logo
              Expanded(
                flex: 3,
                child: Center(
                  child: Image.asset(
                    ImageConstant.logoImage,
                    fit: BoxFit.contain,
                    width: 200,
                    height: 200,
                  ),
                ),
              ),

              // SignUp Form
              Expanded(
                flex: 5,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(50),
                      topRight: Radius.circular(50),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 20),
                    child: Form(
                      key: controller.signUpUserFormKey,
                      child: signUpForm(controller, isAdmin: false),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget signUpForm(SignUpScreenController controller,
      {required bool isAdmin}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextFormField(
          controller: controller.signUpNameController,
          hintText: "enter_name".tr,
          prefixIcon: const Icon(Icons.person,
              color: Color(0xFF0D2C54), size: 20),
          validator: (value) =>
          value == null || value.isEmpty ? "please_enter_name".tr : null,
        ),
        const SizedBox(height: 20),
        CustomTextFormField(
          controller: controller.signUpEmailController,
          hintText: "enter_email".tr,
          prefixIcon: const Icon(Icons.email_outlined,
              color: Color(0xFF0D2C54), size: 20),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "please_enter_email".tr;
            }
            if (!GetUtils.isEmail(value)) {
              return "please_enter_valid_email".tr;
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        CustomTextFormField(
          controller: controller.signUpPasswordController,
          hintText: "enter_password".tr,
          obscureText: controller.isHidden,
          prefixIcon: const Icon(Icons.lock_outlined,
              color: Color(0xFF0D2C54), size: 20),
          suffixIcon: GestureDetector(
            onTap: controller.togglePassword,
            child: Icon(
              controller.isHidden
                  ? Icons.visibility
                  : Icons.visibility_off_rounded,
              color: const Color(0xFF0D2C54),
              size: 20,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "please_enter_password".tr;
            }
            if (value.length < 6) {
              return "password_min_length".tr;
            }
            return null;
          },
        ),
        const SizedBox(height: 30),
        controller.isLoading
            ? const CustomLoadingContainer()
            : CustomElevatedButton(
          text: "signup".tr,
          onPressed: () {
            if (controller.signUpUserFormKey.currentState!.validate()) {
              controller.signUp(isAdmin: false);
            }
          },
        ),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               Text(
                "already_have_account".tr,
                style: TextStyle(fontSize: 14, color: Colors.black),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  Get.offAll(() => const LogInScreen());
                },
                child: Text(
                  "login".tr,
                  style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0D2C54),
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}


// class SignUpScreen extends StatefulWidget {
//   const SignUpScreen({super.key});
//
//   @override
//   State<SignUpScreen> createState() => _SignUpScreenState();
// }
//
// class _SignUpScreenState extends State<SignUpScreen> {
//   @override
//   Widget build(BuildContext context) {
//     final controller = Get.put(SignUpScreenController());
//
//     return GetBuilder<SignUpScreenController>(
//       builder: (controller) {
//         return DefaultTabController(
//           length: 2,
//           child: Scaffold(
//             backgroundColor: const Color(0xFF0D2C54),
//             body: Column(
//               children: [
//                 // Logo
//                 Expanded(
//                   flex: 3,
//                   child: Center(
//                     child: Image.asset(
//                       ImageConstant.logoImage,
//                       fit: BoxFit.contain,
//                       width: 200,
//                       height: 200,
//                     ),
//                   ),
//                 ),
//
//                 // TabBar + SignUp Forms
//                 Expanded(
//                   flex: 5,
//                   child: Container(
//                     width: double.infinity,
//                     decoration: const BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.only(
//                         topLeft: Radius.circular(50),
//                         topRight: Radius.circular(50),
//                       ),
//                     ),
//                     child: Column(
//                       children: [
//                         const SizedBox(height: 16),
//                         Container(
//                           margin: const EdgeInsets.symmetric(
//                               horizontal: 20, vertical: 10),
//                           padding: const EdgeInsets.symmetric(vertical: 6),
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             borderRadius: BorderRadius.circular(30),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.black.withOpacity(0.1),
//                                 blurRadius: 6,
//                                 offset: const Offset(0, 3),
//                               ),
//                             ],
//                           ),
//                           child: TabBar(
//                             indicator: BoxDecoration(
//                               color: const Color(0xFF0D2C54),
//                               borderRadius: BorderRadius.circular(25),
//                             ),
//                             labelColor: Colors.white,
//                             unselectedLabelColor: Colors.black87,
//                             dividerColor: Colors.transparent,
//                             tabs: const [
//                               Padding(
//                                 padding: EdgeInsets.symmetric(horizontal: 40),
//                                 child: Tab(
//                                   child: Text(
//                                     "User",
//                                     style: TextStyle(
//                                         fontSize: 14,
//                                         fontWeight: FontWeight.w600),
//                                   ),
//                                 ),
//                               ),
//                               Padding(
//                                 padding: EdgeInsets.symmetric(horizontal: 40),
//                                 child: Tab(
//                                   child: Text(
//                                     "Admin",
//                                     style: TextStyle(
//                                         fontSize: 14,
//                                         fontWeight: FontWeight.w600),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                         const SizedBox(height: 10),
//
//                         // Forms inside TabBarView
//                         Expanded(
//                           child: TabBarView(
//                             children: [
//                               SingleChildScrollView(
//                                 padding: const EdgeInsets.symmetric(
//                                     horizontal: 30, vertical: 20),
//                                 child: Form(
//                                   key: controller.signUpUserFormKey,
//                                     child: signUpForm(controller, isAdmin: false)),
//                               ),
//                               SingleChildScrollView(
//                                 padding: const EdgeInsets.symmetric(
//                                     horizontal: 30, vertical: 20),
//                                 child: Form(
//                                   key:  controller.signUpAdminFormKey,
//                                     child: signUpForm(controller, isAdmin: true)),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   Widget signUpForm(SignUpScreenController controller,
//       {required bool isAdmin}) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         CustomTextFormField(
//           controller: controller.signUpNameController,
//           hintText: "enter_name".tr,
//           prefixIcon: const Icon(Icons.person,
//               color: Color(0xFF0D2C54), size: 20),
//           validator: (value) =>
//           value == null || value.isEmpty ? "Please enter your name" : null,
//         ),
//         const SizedBox(height: 20),
//         CustomTextFormField(
//           controller: controller.signUpEmailController,
//           hintText: "enter_email".tr,
//           prefixIcon: const Icon(Icons.email_outlined,
//               color: Color(0xFF0D2C54), size: 20),
//           validator: (value) {
//             if (value == null || value.isEmpty) {
//               return "Please enter your email";
//             }
//             if (!GetUtils.isEmail(value)) {
//               return "Please enter a valid email";
//             }
//             return null;
//           },
//         ),
//         const SizedBox(height: 20),
//         CustomTextFormField(
//           controller: controller.signUpPasswordController,
//           hintText: "enter_password".tr,
//           obscureText: controller.isHidden,
//           prefixIcon: const Icon(Icons.lock_outlined,
//               color: Color(0xFF0D2C54), size: 20),
//           suffixIcon: GestureDetector(
//             onTap: controller.togglePassword,
//             child: Icon(
//               controller.isHidden
//                   ? Icons.visibility
//                   : Icons.visibility_off_rounded,
//               color: const Color(0xFF0D2C54),
//               size: 20,
//             ),
//           ),
//           validator: (value) {
//             if (value == null || value.isEmpty) {
//               return "Please enter password";
//             }
//             if (value.length < 6) {
//               return "Password must be at least 6 characters";
//             }
//             return null;
//           },
//         ),
//         const SizedBox(height: 30),
//         controller.isLoading
//             ? const CustomLoadingContainer()
//             : CustomElevatedButton(
//           text: isAdmin ? "Sign Up as Admin" : "Sign Up as User",
//           onPressed: () {
//             final formKey = isAdmin
//                 ? controller.signUpAdminFormKey
//                 : controller.signUpUserFormKey;
//
//             if (formKey.currentState!.validate()) {
//               controller.signUp(isAdmin: isAdmin);
//             }
//           },
//         ),
//         const SizedBox(height: 20),
//         Align(
//           alignment: Alignment.center,
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Text(
//                 "Already have an account?",
//                 style: TextStyle(fontSize: 14, color: Colors.black),
//               ),
//               const SizedBox(width: 4),
//               GestureDetector(
//                 onTap: () {
//                   Get.offAll(() => const LogInScreen());
//                 },
//                 child:  Text(
//                   "Login".tr,
//                   style: TextStyle(
//                       fontSize: 14,
//                       color: Color(0xFF0D2C54),
//                       fontWeight: FontWeight.w600),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(height: 30),
//       ],
//     );
//   }
// }
