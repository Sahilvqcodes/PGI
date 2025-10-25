import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboardControllerScreen extends GetxController {
  // Search controller
  TextEditingController searchController = TextEditingController();

  // Supabase client reference
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void onInit() {
    super.onInit();
    // Trigger update whenever search text changes
    searchController.addListener(() {
      update();
    });
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
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
