import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:translator/translator.dart';


class DashboardScreenController extends GetxController {
  TextEditingController searchController = TextEditingController();
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> allDepartments = [];
  List<Map<String, dynamic>> filteredDepartments = [];
  bool isLoading = false;
  Set<String> translatedIds = {}; // Track which departments have been translated

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(() {
      filterDepartments();
    });
    fetchDepartments();
  }

  // Fetch departments with JOIN
  Future<void> fetchDepartments({bool showLoading = true}) async {
    try {
      if (showLoading) {
        isLoading = true;
        update();
      }

      final data = await _supabase
          .from('department')
          .select('id, name:department_name(id, english, hindi, punjabi), images, floor_number, location, room_number, created_at')
          .order('created_at', ascending: false);

      allDepartments = List<Map<String, dynamic>>.from(data);
      filteredDepartments = List.from(allDepartments);

      if (showLoading) {
        isLoading = false;
      }
      update();
    } catch (e) {
      if (showLoading) {
        isLoading = false;
      }
      update();
      Get.snackbar('Error', 'Failed to fetch departments: ${e.toString()}');
    }
  }

  // Filter departments based on search text
  void filterDepartments() {
    final searchText = searchController.text.toLowerCase();
    final selectedLang = Get.locale?.languageCode ?? 'en';

    if (searchText.isEmpty) {
      filteredDepartments = List.from(allDepartments);
    } else {
      filteredDepartments = allDepartments.where((data) {
        final nameData = data['name'];
        String name = '';
        if (nameData != null && nameData is Map) {
          if (selectedLang == 'hi') {
            name = nameData['hindi'] ?? nameData['english'] ?? '';
          } else if (selectedLang == 'pa') {
            name = nameData['punjabi'] ?? nameData['english'] ?? '';
          } else {
            name = nameData['english'] ?? '';
          }
        }
        return name.toLowerCase().contains(searchText);
      }).toList();
    }
    update();
  }

  // Get display name based on selected language
  String getDisplayName(Map<String, dynamic> nameData, String selectedLang) {
    if (selectedLang == 'hi') {
      return nameData['hindi'] ?? nameData['english'] ?? 'Unknown';
    } else if (selectedLang == 'pa') {
      return nameData['punjabi'] ?? nameData['english'] ?? 'Unknown';
    } else {
      return nameData['english'] ?? 'Unknown';
    }
  }

  // Get first image URL from images field
  String? getFirstImageUrl(dynamic images) {
    if (images == null) return null;

    try {
      if (images is String) {
        // Try to parse JSON string
        String imagesStr = images.replaceAll(r'\"', '"').trim();
        final decoded = jsonDecode(imagesStr);
        if (decoded is List && decoded.isNotEmpty) {
          final firstItem = decoded[0];
          if (firstItem is String && firstItem.startsWith('http')) {
            return firstItem;
          }
        }
      } else if (images is List && images.isNotEmpty) {
        // Already a list
        final firstItem = images[0];
        if (firstItem is String && firstItem.startsWith('http')) {
          return firstItem;
        }
      }
    } catch (e) {
      print("Error parsing images: $e");
    }

    return null;
  }

  // Auto-translate and save to Supabase
  Future<void> autoTranslateAndSave(
      String nameId, String english, String? hindi, String? punjabi) async {
    // Skip if already translated this department
    if (translatedIds.contains(nameId)) {
      return;
    }

    final translator = GoogleTranslator();

    try {
      // Skip if all 3 languages already exist
      if (hindi != null &&
          hindi.isNotEmpty &&
          punjabi != null &&
          punjabi.isNotEmpty &&
          hindi != english &&
          punjabi != english) {
        translatedIds.add(nameId); // Mark as processed
        return;
      }

      print("🌐 Translating: $english");

      // Mark as being translated to prevent duplicate calls
      translatedIds.add(nameId);

      // Translate to Hindi if missing
      String hindiText = (hindi == null || hindi.isEmpty || hindi == english)
          ? (await translator.translate(english, to: 'hi')).text
          : hindi;

      // Translate to Punjabi if missing
      String punjabiText = (punjabi == null || punjabi.isEmpty || punjabi == english)
          ? (await translator.translate(english, to: 'pa')).text
          : punjabi;

      // Update department_name table
      await _supabase.from('department_name').update({
        'hindi': hindiText,
        'punjabi': punjabiText,
      }).eq('id', nameId);

      print("✅ Supabase updated with Hindi & Punjabi translations");

      // Refresh data to show updated translations (without showing loading)
      await fetchDepartments(showLoading: false);
    } catch (e) {
      print("❌ Translation error: $e");
      // Remove from translated set on error so it can be retried
      translatedIds.remove(nameId);
    }
  }
}




