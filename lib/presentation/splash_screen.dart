import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import '../core/image_constants.dart';
import '../core/pref_utils.dart';
import '../services/supabase_services.dart';
import 'AdminDashboardScreen/admin_dashboard_screen.dart';
import 'dashboardScreen/dashboard_Screen.dart';
import 'logInScreen/logIn_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initSplashFlow();
  }

  Future<void> _initSplashFlow() async {
    await PrefUtils().init();

    await getCurrentLocation();

    await _checkUserAndLanguage();
  }

  Future<void> _checkUserAndLanguage() async {
    bool isLoggedIn = PrefUtils.getLoggedIn();
    String role = PrefUtils.getUserRole(); // "admin" or "user"
    bool isLanguageSelected = PrefUtils.getLanguage();

    // Check Supabase session to verify authentication
    bool hasSupabaseSession = SupabaseServices.isLoggedIn();

    print("✅ Login: $isLoggedIn | Role: $role | Language selected: $isLanguageSelected | Supabase Session: $hasSupabaseSession");

    await Future.delayed(const Duration(seconds: 1)); // splash delay

    // If SharedPreferences says logged in but no Supabase session, clear prefs
    if (isLoggedIn && !hasSupabaseSession) {
      await PrefUtils.clearPreferencesData();
      isLoggedIn = false;
    }

    if (isLoggedIn) {
      // already logged in
      if (role == 'admin') {
        Get.offAll(() => const AdminDashboardScreen());
      } else {
        Get.offAll(() => const DashBoardScreen());
      }
    } else {
      // not logged in
      if (isLanguageSelected) {
        Get.offAll(() => const LogInScreen());
      } else {
        showLanguageDialog();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Image.asset(
          ImageConstant.splashScreen,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  /// Language select dialog
  void showLanguageDialog() {
    showDialog(
      context: Get.context!,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Choose Language", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.language, color: Colors.blue),
                title: const Text("English"),
                onTap: () async {
                  Get.updateLocale(const Locale('en', 'US'));
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
                  child: const Text("Skip"),
                ),
              ),
            ],
          ),
        );
      },
    ).then((value) {
      if (value != null) {
        showLoginOrGuestDialog();
        print("🌐 Selected Language: $value");
      }
    });
  }

  /// Second dialog - Login or Guest
  void showLoginOrGuestDialog() {
    showDialog(
      context: Get.context!,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Continue as", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.login, color: Colors.blue),
                title: const Text("Login"),
                onTap: () {
                  Navigator.pop(context);
                  Get.offAll(() => const LogInScreen());
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.person_outline, color: Colors.green),
                title: const Text("Try as Guest"),
                onTap: () {
                  Navigator.pop(context);
                  Get.offAll(() => const DashBoardScreen());
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // / Location permission logic
  Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        return null; // Service on karne ke baad wapas aayega
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        return null;
      }

      // Try high accuracy, fallback low accuracy
      try {
        return await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
      } catch (e) {
        return await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low);
      }
    } catch (e) {
      print("❌ Location error: $e");
      return null;
    }
  }
}
