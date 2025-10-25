import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/app_constants.dart';
import 'core/pref_utils.dart';
import 'localization/app_localization.dart';
import 'presentation/splash_screen.dart';

const LatLng pgiCenter = LatLng(30.7649, 76.7739);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: AppConstants.SUPABASE_URL,
    anonKey: AppConstants.SUPABASE_ANON_KEY,
  );

  // Saved language read karo
  Locale? savedLocale = await PrefUtils.getLanguageSelect();

  runApp(MyApp(savedLocale: savedLocale));
}
class MyApp extends StatelessWidget {
  final Locale? savedLocale;
  const MyApp({super.key, this.savedLocale});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'PGI Map App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      locale: savedLocale ?? const Locale('en', 'US'),
      translations: AppLocalization(),
      fallbackLocale: const Locale('en', 'US'),
      home: const SplashScreen(),
    );
  }
}
