import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:translator/translator.dart';

class AdminDashboardControllerScreen extends GetxController {
  // Search controller
  TextEditingController searchController = TextEditingController();

  // Supabase client reference
  final SupabaseClient _supabase = Supabase.instance.client;

  // Data
  List<Map<String, dynamic>> allDepartments = [];
  List<Map<String, dynamic>> filteredDepartments = [];
  bool isLoading = false;

  @override
  void onInit() {
    super.onInit();
    // Trigger update whenever search text changes
    searchController.addListener(() {
      filterDepartments();
    });
    fetchDepartments(showLoading:  true);
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  // Fetch departments with JOIN
  Future<void> fetchDepartments({bool? showLoading}) async {
    try {
      if (showLoading ?? false) {
        isLoading = true;
        update();
      }

      final data = await _supabase
          .from('department')
          .select('id, name:department_name(id, english, hindi, punjabi), images, floor_number, location, room_number');

      allDepartments = List<Map<String, dynamic>>.from(data);
      filteredDepartments = List.from(allDepartments);

      if (showLoading ?? false) {
        isLoading = false;
      }
      update();
    } catch (e) {
      if (showLoading ?? false) {
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

  // Auto-translate and save to Supabase
  Future<void> autoTranslateAndSave(
      String nameId, String english, String? hindi, String? punjabi) async {
    final translator = GoogleTranslator();

    try {
      // Skip if all 3 languages already exist
      if (hindi != null &&
          hindi.isNotEmpty &&
          punjabi != null &&
          punjabi.isNotEmpty &&
          hindi != english &&
          punjabi != english) {
        return;
      }

      print("🌐 Translating: $english");

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

      // Refresh data to show updated translations
      await fetchDepartments();
    } catch (e) {
      print("❌ Translation error: $e");
    }
  }

  // Delete a department by ID
  Future<void> deleteDepartment(String id) async {
    try {
      // First get the name_id to delete from department_name table
      final dept = await _supabase
          .from('department')
          .select('name')
          .eq('id', id)
          .single();

      final nameId = dept['name'];

      // Delete from department table
      await _supabase.from('department').delete().eq('id', id);

      // Delete from department_name table
      if (nameId != null) {
        await _supabase.from('department_name').delete().eq('id', nameId);
      }

      // Refresh the list to reflect changes (silently, without loading indicator)
      await fetchDepartments(showLoading: false);

      Get.snackbar('Success', 'Department deleted successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete department: ${e.toString()}');
    }
  }

  // Update a department by ID
  Future<void> updateDepartment(String id, Map<String, dynamic> updatedData) async {
    try {
      await _supabase.from('department').update(updatedData).eq('id', id);
      Get.snackbar('Success', 'Department updated successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update department: ${e.toString()}');
    }
  }
}
