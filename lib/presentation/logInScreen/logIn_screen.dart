import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/image_constants.dart';
import '../../widgets/popMenuButton.dart';
import '../dashboardScreen/dashboard_Screen.dart';
import 'controller/login_screen_controller.dart';
import 'signUpScreen.dart';
import 'package:chandigarh/widgets/custom_text_form_field.dart';
import 'package:chandigarh/widgets/custom_elevated_button.dart';
import 'package:chandigarh/widgets/custom_loading_container.dart';

class LogInScreen extends StatefulWidget {
  const LogInScreen({super.key});

  @override
  State<LogInScreen> createState() => _LogInScreenState();
}

class _LogInScreenState extends State<LogInScreen> {
  @override
  void initState() {
    super.initState();
    // Delete old controller if it exists to avoid using disposed controllers
    if (Get.isRegistered<LoginScreenController>()) {
      Get.delete<LoginScreenController>();
    }
    // Create a fresh controller
    Get.put(LoginScreenController());
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LoginScreenController>(
      builder: (controller) {
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            backgroundColor: const Color(0xFF0D2C54),
            body: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Center(
                        child: Image.asset(
                          ImageConstant.logoImage,
                          width: 200,
                          height: 200,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    // TabBar + Forms
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
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 20),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: TabBar(
                                indicator: BoxDecoration(
                                  color: const Color(0xFF0D2C54),
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                labelColor: Colors.white,
                                unselectedLabelColor: Colors.black87,
                                dividerColor: Colors.transparent,
                                tabs: [
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 30),
                                    child: Tab(
                                      child: Center(
                                        child: Text(
                                          "user".tr,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 30),
                                    child: Tab(
                                      child: Center(
                                        child: Text(
                                          "admin".tr,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Expanded(
                              child: TabBarView(
                                children: [
                                  SingleChildScrollView(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 30, vertical: 20),
                                    child: Form(
                                        key: controller.formKeyUser,
                                        child:
                                            loginForm(controller, isAdmin: false)),
                                  ),
                                  SingleChildScrollView(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 30, vertical: 20),
                                    child: Form(
                                        key: controller.formKeyAdmin,
                                        child:
                                            loginForm(controller, isAdmin: true)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                Positioned(
                  top: 50,
                  right: 16,
                  child: GestureDetector(
                    onTap: () {
                      showLanguageDialog();
                    },
                    child: Icon(
                      Icons.language,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget loginForm(
    LoginScreenController controller, {
    required bool isAdmin,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextFormField(
          controller: controller.emailController,
          hintText: "enter_email".tr,
          prefixIcon: const Icon(
            Icons.email_outlined,
            color: Color(0xFF0D2C54),
            size: 20,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              RegExp(r'[a-zA-Z0-9@._\-]'), // added @ . _ -
            ),
          ],
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
          controller: controller.passwordController,
          hintText: "enter_password".tr,
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              RegExp(r'[a-zA-Z0-9!@#\$%\^&*()_\-+=<>?/.,;:]'),
            ),
          ],
          obscureText: controller.isHidden,
          prefixIcon: const Icon(
            Icons.lock_outlined,
            color: Color(0xFF0D2C54),
            size: 20,
          ),
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
                text: isAdmin ? "login_as_admin".tr : "login_as_user".tr,
                onPressed: () {
                  final formKey = isAdmin
                      ? controller.formKeyAdmin
                      : controller.formKeyUser;

                  if (formKey.currentState!.validate()) {
                    controller.isAdmin = isAdmin;
                    controller.login();
                  }
                },
              ),
        const SizedBox(height: 20),
        (isAdmin)
            ? SizedBox()
            : Align(
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("dont_have_account".tr),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        Get.offAll(() => const SignUpScreen());
                      },
                      child: Text(
                        "signup".tr,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF0D2C54),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        const SizedBox(height: 30),

        // Only show Try as Guest if User tab is active
        if (!isAdmin)
          Align(
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: () {
                Get.offAll(() => DashBoardScreen());
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                decoration: BoxDecoration(
                  color: Color(0xFF0D2C54),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  "try_as_guest".tr,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

        const SizedBox(height: 30),
      ],
    );
  }
}
