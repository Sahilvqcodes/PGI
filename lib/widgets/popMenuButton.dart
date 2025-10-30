import 'package:chandigarh/core/pref_utils.dart';
import 'package:chandigarh/presentation/logInScreen/logIn_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../services/supabase_services.dart';
import '../presentation/splash_screen.dart';

class CustomMenuDropdown extends StatefulWidget {
  const CustomMenuDropdown({super.key});

  @override
  State<CustomMenuDropdown> createState() => _CustomMenuDropdownState();
}

class _CustomMenuDropdownState extends State<CustomMenuDropdown> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  bool _isDropdownOpen = false;
  bool isLogoutClicked = false;

  void _toggleDropdown() {
    if (_isDropdownOpen) {
      _overlayEntry?.remove();
      _isDropdownOpen = false;
    } else {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
      _isDropdownOpen = true;
    }
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;
    var offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Transparent barrier to detect outside clicks
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleDropdown,
              behavior: HitTestBehavior.translucent,
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
          // Dropdown menu
          Positioned(
            top: offset.dy + size.height + 5,
            left: offset.dx,
            width: 180,
            child: Material(
              color: Colors.transparent,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: Offset(0, size.height + 5),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildMenuItem(
                        "logout".tr,
                        isLogoutClicked
                            ? () {}
                            : () async {
                                isLogoutClicked = true;
                                setState(
                                    () {}); // Update UI immediately to disable button

                                try {
                                  print("Logout clicked");
                                  await SupabaseServices.signOut();
                                  await PrefUtils.clearPreferencesData();
                                  Get.offAll(() => LogInScreen());
                                } catch (e) {
                                  print("Error during logout: $e");
                                }
                              },
                      ),
                      _buildMenuItem("language_select".tr, () async {
                        showLanguageDialog();
                        print("Language select clicked");

                        _toggleDropdown();
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
              fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleDropdown,
        child: const Icon(Icons.menu, color: Colors.white, size: 30),
      ),
    );
  }

  void showLanguageDialog() {
    showDialog(
      context: Get.context!,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("choose_language".tr,
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.language, color: Colors.blue),
                title: const Text("English"),
                onTap: () async {
                  Get.updateLocale(const Locale('en', 'US'));
                  await PrefUtils.setLanguageCode('en', 'US');
                  await PrefUtils.setLanguage(true);
                  Navigator.pop(context, "English");
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.translate, color: Colors.green),
                title: const Text("हिंदी (Hindi)"),
                onTap: () async {
                  Get.updateLocale(const Locale('hi', 'IN'));
                  await PrefUtils.setLanguageCode('hi', 'IN');
                  await PrefUtils.setLanguage(true);
                  Navigator.pop(context, "Hindi");
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.g_translate, color: Colors.red),
                title: const Text("ਪੰਜਾਬੀ (Punjabi)"),
                onTap: () async {
                  Get.updateLocale(const Locale('pa', 'IN'));
                  await PrefUtils.setLanguageCode('pa', 'IN');
                  await PrefUtils.setLanguage(true);
                  Navigator.pop(context, "Punjabi");
                },
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: TextButton(
                  onPressed: () async {
                    await PrefUtils.setLanguage(true);
                    Navigator.pop(context, "Skip");
                  },
                  child: Text("skip".tr),
                ),
              ),
            ],
          ),
        );
      },
    ).then((value) {
      if (value != null) {
        print("🌐 Selected Language: $value");
      }
    });
  }
}
