import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:translator/translator.dart';
import '../../../widgets/custom_toast.dart';
import '../admin_dashboard_screen.dart';
import 'admin_dashboard_controller_screen.dart';

class AddDepartmentControllerScreen extends GetxController
    with WidgetsBindingObserver {
  TextEditingController departmentName = TextEditingController();
  TextEditingController location = TextEditingController();
  TextEditingController floorNumber = TextEditingController();
  TextEditingController roomNumber = TextEditingController();

  bool isLoading = false;
  final List<File> images = [];
  final List<String> existingImageUrls = []; // For editing existing images
  final List<bool> imageLoadingStates =
      []; // Track loading state for each image
  final keyDepartment = GlobalKey<FormState>();
  bool fetchingLocation = false;

  // Edit mode fields
  bool isEditing = false;
  String? recordId;

  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    getCurrentLocation();

    final args = Get.arguments;
    if (args != null) {
      isEditing = true;
      recordId = args['id']?.toString();
      final data = args['data'] as Map<String, dynamic>;
      final nameData = data['name'];
      if (nameData != null && nameData is Map) {
        departmentName.text = nameData['english'] ?? '';
      }

      location.text = data['location'] ?? '';
      floorNumber.text = data['floor_number']?.toString() ?? '';
      roomNumber.text = data['room_number']?.toString() ?? '';

      if (data['images'] != null) {
        if (data['images'] is String) {
          String imagesStr = data['images'] as String;
          imagesStr = imagesStr.replaceAll(r'\"', '"').trim();

          try {
            final decoded = jsonDecode(imagesStr);
            if (decoded is List) {
              for (var item in decoded) {
                if (item is String &&
                    item.isNotEmpty &&
                    item.startsWith('http')) {
                  existingImageUrls.add(item);
                }
              }
            }
          } catch (e) {
            print("Failed to decode images JSON: $e");
          }
        } else if (data['images'] is List) {
          for (var item in data['images']) {
            if (item is String && item.isNotEmpty && item.startsWith('http')) {
              existingImageUrls.add(item);
            }
          }
        }
      }
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this); // 👈 yaha add karo
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      getCurrentLocation();
    }
  }

  /// Validate location field contains proper Lat/Long format
  String? validateLocation(String? value) {
    if (value == null || value.isEmpty) {
      return "location_required".tr;
    }

    // Check for error states
    if (value.contains("location_disabled") ||
        value.contains("location_denied_forever")) {
      return "please_enable_location_services".tr;
    }

    if (value.contains("fetching_location") ||
        value.contains("failed_to_fetch_location")) {
      return "please_wait_for_location".tr;
    }

    // Validate Lat/Long format: "Lat: XX.XXXX, Lon: YY.YYYY"
    final latLonPattern = RegExp(r'Lat:\s*-?\d+\.\d+,\s*Lon:\s*-?\d+\.\d+');
    if (!latLonPattern.hasMatch(value)) {
      return "please_enable_location_to_save_data".tr;
    }

    return null; // Validation passed
  }

  /// Validate floor number is not empty
  String? validateFloorNumber(String? value) {
    if (value == null || value.isEmpty) {
      return "please_enter_floor_number".tr;
    }
    return null;
  }

  /// Validate room number is not empty
  String? validateRoomNumber(String? value) {
    if (value == null || value.isEmpty) {
      return "please_enter_room_number".tr;
    }
    return null;
  }

  /// Translate department name to all three languages
  Future<Map<String, String>> translateDepartmentName(String inputText) async {
    final translator = GoogleTranslator();

    try {
      bool isHindiScript = RegExp(r'[\u0900-\u097F]').hasMatch(inputText);
      bool isPunjabiScript = RegExp(r'[\u0A00-\u0A7F]').hasMatch(inputText);

      String englishText = inputText;
      String hindiText = inputText;
      String punjabiText = inputText;

      if (isHindiScript) {
        hindiText = inputText;
        final englishTranslation =
            await translator.translate(inputText, from: 'hi', to: 'en');
        englishText = englishTranslation.text;
        final punjabiTranslation =
            await translator.translate(englishText, from: 'en', to: 'pa');
        punjabiText = punjabiTranslation.text;
      } else if (isPunjabiScript) {
        punjabiText = inputText;
        final englishTranslation =
            await translator.translate(inputText, from: 'pa', to: 'en');
        englishText = englishTranslation.text;
        final hindiTranslation =
            await translator.translate(englishText, from: 'en', to: 'hi');
        hindiText = hindiTranslation.text;
      } else {
        englishText = inputText;
        final hindiTranslation =
            await translator.translate(englishText, from: 'en', to: 'hi');
        hindiText = hindiTranslation.text;
        final punjabiTranslation =
            await translator.translate(englishText, from: 'en', to: 'pa');
        punjabiText = punjabiTranslation.text;
      }

      // --- Smart fallback ---
      if (hindiText.toLowerCase() == englishText.toLowerCase()) {
        hindiText = await smartTransliteration(englishText, 'hi', translator);
      }
      if (punjabiText.toLowerCase() == englishText.toLowerCase()) {
        punjabiText = await smartTransliteration(englishText, 'pa', translator);
      }
      return {
        'english': englishText,
        'hindi': hindiText,
        'punjabi': punjabiText,
      };
    } catch (e) {
      print("❌ Translation error: $e");
      return {
        'english': inputText,
        'hindi': inputText,
        'punjabi': inputText,
      };
    }
  }

  /// Upload a single image to Supabase Storage
  Future<String?> uploadImage(File file) async {
    try {
      print("Uploading file: ${file.path}");
      String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final bytes = await file.readAsBytes();

      // Upload to Supabase Storage
      final path = await _supabase.storage
          .from('department_images')
          .uploadBinary('$fileName', bytes);

      // Get public URL
      final String downloadUrl =
          _supabase.storage.from('department_images').getPublicUrl(fileName);

      print("Upload success: $downloadUrl");
      return downloadUrl;
    } catch (e) {
      print("Upload error: $e");
      return null;
    }
  }

  Future<void> saveDepartment() async {
    if (!keyDepartment.currentState!.validate()) return;

    isLoading = true;
    update();

    while (fetchingLocation) {
      await Future.delayed(Duration(milliseconds: 200));
    }

    try {
      List<String> imageUrls = List<String>.from(existingImageUrls);
      for (File file in images) {
        String? url = await uploadImage(file);
        if (url != null) {
          imageUrls.add(url);
        } else {
          CustomToast.showToast("Image upload failed");
        }
      }
      final translations =
          await translateDepartmentName(departmentName.text.trim());
      String? nameId;

      if (isEditing && recordId != null) {
        final existing = await _supabase
            .from('department')
            .select('name')
            .eq('id', recordId!)
            .single();

        nameId = existing['name'];

        await _supabase.from('department_name').update({
          'english': translations['english']!,
          'hindi': translations['hindi']!,
          'punjabi': translations['punjabi']!,
        }).eq('id', nameId!);

        // Update department table
        await _supabase.from('department').update({
          'location': location.text.trim(),
          'floor_number': floorNumber.text.trim(),
          'room_number': roomNumber.text.trim(),
          'images': imageUrls,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', recordId!);
        CustomToast.showToast("Department updated successfully",color: Colors.green,);
      } else {
        final nameResponse = await _supabase
            .from('department_name')
            .insert({
              'english': translations['english']!,
              'hindi': translations['hindi']!,
              'punjabi': translations['punjabi']!,
            })
            .select()
            .single();

        nameId = nameResponse['id'].toString();
        await _supabase.from('department').insert({
          'name': nameId,
          'location': location.text.trim(),
          'floor_number': floorNumber.text.trim(),
          'room_number': roomNumber.text.trim(),
          'images': imageUrls,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        CustomToast.showToast("Department added successfully",color: Colors.green,);
      }

      // Clear form
      departmentName.clear();
      location.clear();
      floorNumber.clear();
      roomNumber.clear();
      images.clear();
      existingImageUrls.clear();

      // Refresh admin dashboard to show new/updated department (silently, without loading indicator)
      if (Get.isRegistered<AdminDashboardControllerScreen>()) {
        await Get.find<AdminDashboardControllerScreen>()
            .fetchDepartments(showLoading: false);
      }

      Get.offAll(() => AdminDashboardScreen());
    } catch (e) {
      print("Supabase error: $e");
      CustomToast.showToast("Failed to save department");
    } finally {
      isLoading = false;
      update();
    }
  }

  Future<void> openCamera() async {
    final picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      // Add loading state and placeholder immediately
      imageLoadingStates.add(true);
      images.add(File('')); // Temporary placeholder
      update();

      // Compress image in background
      File? compressed = await compressImage(File(photo.path));
      if (compressed != null) {
        images[images.length - 1] =
            compressed; // Replace placeholder with actual image
        imageLoadingStates[imageLoadingStates.length - 1] = false;
        print("Image added from camera: ${compressed.path}");
      } else {
        // Remove failed image
        images.removeLast();
        imageLoadingStates.removeLast();
      }
      update();
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      // Add loading state and placeholder immediately
      imageLoadingStates.add(true);
      images.add(File('')); // Temporary placeholder
      update();

      // Compress image in background
      File? compressed = await compressImage(File(picked.path));
      if (compressed != null) {
        images[images.length - 1] =
            compressed; // Replace placeholder with actual image
        imageLoadingStates[imageLoadingStates.length - 1] = false;
        print("Image added from gallery: ${compressed.path}");
      } else {
        // Remove failed image
        images.removeLast();
        imageLoadingStates.removeLast();
      }
      update();
    }
  }

  // Remove existing image URL
  void removeExistingImage(int index) {
    if (index >= 0 && index < existingImageUrls.length) {
      existingImageUrls.removeAt(index);
      update();
    }
  }

  // Remove newly picked image
  void removeNewImage(int index) {
    if (index >= 0 && index < images.length) {
      images.removeAt(index);
      if (index < imageLoadingStates.length) {
        imageLoadingStates.removeAt(index);
      }
      update();
    }
  }

  Future<File?> compressImage(File file) async {
    try {
      print("Compressing file: ${file.path}");
      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        print("Decode failed!");
        return null;
      }

      final resized = img.copyResize(decoded, width: 800);
      final compressedBytes = img.encodeJpg(resized, quality: 40);

      final tempDir = await getTemporaryDirectory();
      final path =
          '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

      final compressedFile = await File(path).writeAsBytes(compressedBytes);
      print("Compressed file path: $path");
      return compressedFile;
    } catch (e) {
      print("Compression error: $e");
      return null;
    }
  }

  Future<void> getCurrentLocation() async {
    location.text = "fetching_location".tr;
    fetchingLocation = true;
    update();

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      location.text = "location_disabled".tr;
      fetchingLocation = false;
      update();
      showLocationDialog();
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        location.text = "location_disabled".tr;
        fetchingLocation = false;
        update();
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      location.text = "location_denied_forever".tr;
      fetchingLocation = false;
      update();
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      location.text = "Lat: ${position.latitude}, Lon: ${position.longitude}";
      fetchingLocation = false;
      update(); // GetBuilder ko refresh kar do

      print("Latitude: ${position.latitude}, Longitude: ${position.longitude}");
    } catch (e) {
      location.text = "failed_to_fetch_location".tr;
      fetchingLocation = false;
      update();
    }
  }

  void showLocationDialog() {
    Get.dialog(
      AlertDialog(
        title: Text("location_required".tr),
        content: Text("please_turn_on_location".tr),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
            },
            child: Text("cancel".tr),
          ),
          TextButton(
            onPressed: () async {
              await Geolocator.openLocationSettings();
              Get.back(); // Dialog close
            },
            child: Text("enable".tr),
          )
        ],
      ),
      barrierDismissible: false,
    );
  }

  Future<String> smartTransliteration(
      String word, String to, GoogleTranslator translator) async {
    final match = RegExp(r'^([A-Z][a-z]?)([a-z]+)$').firstMatch(word);
    if (match != null) {
      String prefix = match.group(1)!;
      String suffix = match.group(2)!;

      final translatedSuffix =
          (await translator.translate(suffix, from: 'en', to: to)).text;

      final transliteratedPrefix = transliterateLetters(prefix, to);

      return "$transliteratedPrefix$translatedSuffix";
    }

    return transliterateLetters(word, to);
  }

  String transliterateLetters(String word, String to) {
    final hindiMap = {
      'a': 'ए',
      'b': 'बी',
      'c': 'सी',
      'd': 'डी',
      'e': 'ई',
      'f': 'एफ',
      'g': 'जी',
      'h': 'एच',
      'i': 'आई',
      'j': 'जे',
      'k': 'के',
      'l': 'एल',
      'm': 'एम',
      'n': 'एन',
      'o': 'ओ',
      'p': 'पी',
      'q': 'क्यू',
      'r': 'आर',
      's': 'एस',
      't': 'टी',
      'u': 'यू',
      'v': 'वी',
      'w': 'डब्ल्यू',
      'x': 'एक्स',
      'y': 'वाई',
      'z': 'जेड'
    };

    final punjabiMap = {
      'a': 'ਏ',
      'b': 'ਬੀ',
      'c': 'ਸੀ',
      'd': 'ਡੀ',
      'e': 'ਈ',
      'f': 'ਐਫ',
      'g': 'ਜੀ',
      'h': 'ਐਚ',
      'i': 'ਆਈ',
      'j': 'ਜੇ',
      'k': 'ਕੇ',
      'l': 'ਐਲ',
      'm': 'ਐਮ',
      'n': 'ਐਨ',
      'o': 'ਓ',
      'p': 'ਪੀ',
      'q': 'ਕਿਊ',
      'r': 'ਆਰ',
      's': 'ਐਸ',
      't': 'ਟੀ',
      'u': 'ਯੂ',
      'v': 'ਵੀ',
      'w': 'ਡਬਲਯੂ',
      'x': 'ਐਕਸ',
      'y': 'ਵਾਈ',
      'z': 'ਜੈਡ'
    };

    final map = to == 'hi' ? hindiMap : punjabiMap;

    return word.split('').map((ch) => map[ch.toLowerCase()] ?? ch).join('');
  }
}
