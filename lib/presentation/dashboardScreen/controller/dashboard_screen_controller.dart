import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class DashboardScreenController extends GetxController {
  TextEditingController searchController = TextEditingController();

  final SupabaseClient _supabase = Supabase.instance.client;

  List<String> allDepartments = [];
  List<String> filteredDepartments = [];

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(() {
      filterDepartments(searchController.text);
    });
  }

  void filterDepartments(String query) {
    if (query.isEmpty) {
      filteredDepartments = List.from(allDepartments);
    } else {
      filteredDepartments = allDepartments
          .where((dept) => dept.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    update();
  }
}




