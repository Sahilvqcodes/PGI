import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final keyDepartment = GlobalKey<FormState>();

  // Edit mode fields
  bool isEditing = false;
  String? recordId;

  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    getCurrentLocation();

    // Check if data is passed via Get.arguments
    final args = Get.arguments;
    if (args != null) {
      isEditing = true;
      recordId = args['id']?.toString();
      final data = args['data'] as Map<String, dynamic>;
      // Get department name from department_name table
      final nameData = data['name'];
      if (nameData != null && nameData is Map) {
        // Use English as default for editing
        departmentName.text = nameData['english'] ?? '';
      }

      location.text = data['location'] ?? '';
      floorNumber.text = data['floor_number']?.toString() ?? '';
      roomNumber.text = data['room_number']?.toString() ?? '';

      // Load existing image URLs if any
      if (data['images'] != null && data['images'] is List) {
        for (var item in data['images']) {
          if (item is String && item.isNotEmpty && item.startsWith('http')) {
            existingImageUrls.add(item);
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
      // User wapas app me aaya → location check karlo
      getCurrentLocation();
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

    try {
      // Start with clean list of existing image URLs
      List<String> imageUrls = List<String>.from(existingImageUrls);

      // Upload new images if added
      for (File file in images) {
        String? url = await uploadImage(file);
        if (url != null) {
          imageUrls.add(url);
        } else {
          Get.snackbar("Error", "Image upload failed");
        }
      }

      String? nameId;

      if (isEditing && recordId != null) {
        // Get existing department to find name_id
        final existing = await _supabase
            .from('department')
            .select('name')
            .eq('id', recordId!)
            .single();

        nameId = existing['name'];

        // Update department_name table
        await _supabase.from('department_name').update({
          'english': departmentName.text.trim(),
          'hindi': departmentName.text.trim(), // Will be auto-translated
          'punjabi': departmentName.text.trim(), // Will be auto-translated
        }).eq('id', nameId!);

        // Update department table
        await _supabase.from('department').update({
          'location': location.text.trim(),
          'floor_number': floorNumber.text.trim(),
          'room_number': roomNumber.text.trim(),
          'images': imageUrls,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', recordId!);

        Get.snackbar("Success", "Department updated successfully");
      } else {
        // Create new department_name entry
        final nameResponse = await _supabase
            .from('department_name')
            .insert({
              'english': departmentName.text.trim(),
              'hindi': departmentName.text.trim(), // Will be auto-translated
              'punjabi': departmentName.text.trim(), // Will be auto-translated
            })
            .select()
            .single();

        nameId = nameResponse['id'].toString();

        // Create new department entry
        await _supabase.from('department').insert({
          'name': nameId,
          'location': location.text.trim(),
          'floor_number': floorNumber.text.trim(),
          'room_number': roomNumber.text.trim(),
          'images': imageUrls,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });

        Get.snackbar("Success", "Department added successfully");
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
        await Get.find<AdminDashboardControllerScreen>().fetchDepartments(showLoading: false);
      }

      Get.offAll(() => AdminDashboardScreen());
    } catch (e) {
      print("Supabase error: $e");
      Get.snackbar("Error", "Failed to save department: ${e.toString()}");
    } finally {
      isLoading = false;
      update();
    }
  }

  Future<void> openCamera() async {
    final picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      File? compressed = await compressImage(File(photo.path));
      if (compressed != null) {
        images.add(compressed);
        print("Image added from camera: ${compressed.path}");
      }
      update();
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      File? compressed = await compressImage(File(picked.path));
      if (compressed != null) {
        images.add(compressed);
        print("Image added from gallery: ${compressed.path}");
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
    update();

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      location.text = "location_disabled".tr;
      update();
      showLocationDialog();
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        location.text = "location_disabled".tr;
        update();
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      location.text = "location_denied_forever".tr;
      update();
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      location.text = "Lat: ${position.latitude}, Lon: ${position.longitude}";
      update(); // GetBuilder ko refresh kar do

      print("Latitude: ${position.latitude}, Longitude: ${position.longitude}");
    } catch (e) {
      location.text = "failed_to_fetch_location".tr;
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
              await Geolocator.openLocationSettings(); // Settings open
              Get.back(); // Dialog close
            },
            child: Text("enable".tr),
          )
        ],
      ),
      barrierDismissible: false,
    );
  }
}
