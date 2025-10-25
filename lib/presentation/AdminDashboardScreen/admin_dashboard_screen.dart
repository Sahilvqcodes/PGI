import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:translator/translator.dart';

import '../../widgets/custom_text_form_field.dart';
import '../../widgets/popMenuButton.dart';
import 'add_department_screen.dart';
import 'controller/admin_dashboard_controller_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  // Auto-translate and save to Supabase
  Future<void> autoTranslateAndSave(
      String nameId, String english, String? hindi, String? punjabi) async {
    final translator = GoogleTranslator();
    final supabase = Supabase.instance.client;

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
      String punjabiText =
          (punjabi == null || punjabi.isEmpty || punjabi == english)
              ? (await translator.translate(english, to: 'pa')).text
              : punjabi;

      // Update department_name table
      await supabase.from('department_name').update({
        'hindi': hindiText,
        'punjabi': punjabiText,
      }).eq('id', nameId);

      print("✅ Supabase updated with Hindi & Punjabi translations");
    } catch (e) {
      print("❌ Translation error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedLang = Get.locale?.languageCode ?? 'en';
    final supabase = Supabase.instance.client;

    final controller = Get.isRegistered<AdminDashboardControllerScreen>()
        ? Get.find<AdminDashboardControllerScreen>()
        : Get.put(AdminDashboardControllerScreen(), permanent: true);

    return GetBuilder<AdminDashboardControllerScreen>(
      builder: (controller) => Scaffold(
        body: Stack(
          children: [
            Column(
              children: [
                searchBarContainer(controller),
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: supabase.from('department').select(
                        'id, name:department_name(id, english, hindi, punjabi), images, floor_number, location, room_number'),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                            child: Text("No departments found"));
                      }

                      // Filter departments based on search text
                      final searchText =
                          controller.searchController.text.toLowerCase();
                      final filteredDepts = snapshot.data!.where((data) {
                        final nameData = data['name'];
                        String name = '';
                        if (nameData != null && nameData is Map) {
                          if (selectedLang == 'hi') {
                            name =
                                nameData['hindi'] ?? nameData['english'] ?? '';
                          } else if (selectedLang == 'pa') {
                            name = nameData['punjabi'] ??
                                nameData['english'] ??
                                '';
                          } else {
                            name = nameData['english'] ?? '';
                          }
                        }
                        return name.toLowerCase().contains(searchText);
                      }).toList();

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        itemCount: filteredDepts.length,
                        itemBuilder: (context, index) {
                          var data = filteredDepts[index];
                          var recordId = data['id'].toString();
                          var nameData = data['name'];
                          print("DATA ---- $data");
                          String displayName = 'Unknown';
                          String? nameId;
                          String? english;
                          String? hindi;
                          String? punjabi;

                          if (nameData != null && nameData is Map) {
                            nameId = nameData['id']?.toString();
                            english = nameData['english'];
                            hindi = nameData['hindi'];
                            punjabi = nameData['punjabi'];

                            if (selectedLang == 'hi') {
                              displayName = hindi ?? english ?? 'Unknown';
                            } else if (selectedLang == 'pa') {
                              displayName = punjabi ?? english ?? 'Unknown';
                            } else {
                              displayName = english ?? 'Unknown';
                            }

                            // Auto translate if needed
                            if (nameId != null && english != null) {
                              autoTranslateAndSave(
                                  nameId, english, hindi, punjabi);
                            }
                          }

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            child: ListTile(
                              leading: (data['images'] != null &&
                                      data['images'] is List &&
                                      data['images'].isNotEmpty)
                                  ? CircleAvatar(
                                      backgroundImage:
                                          NetworkImage(data['images'][0]),
                                    )
                                  : const CircleAvatar(
                                      child: Icon(Icons.image)),
                              title: Text(displayName),
                              subtitle: Text(
                                "${'room'.tr}: ${data['room_number'] ?? 'N/A'}\n"
                                "${'floor'.tr}: ${data['floor_number'] ?? 'N/A'}\n"
                                "${'location'.tr}: ${data['location'] ?? 'N/A'}",
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Edit button
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Color(0xFF0D2C54),
                                    ),
                                    onPressed: () {
                                      Get.to(() => AddDepartmentScreen(),
                                          arguments: {
                                            'id': recordId,
                                            'data': data,
                                          });
                                    },
                                  ),

                                  // Delete button
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () {
                                      Get.defaultDialog(
                                        titlePadding: EdgeInsets.only(top: 14),
                                        contentPadding: EdgeInsets.all(14),
                                        title: 'delete_department'.tr,
                                        middleText:
                                            'confirm_delete_department'.tr,
                                        titleStyle: const TextStyle(
                                            color: Colors.black),
                                        middleTextStyle: const TextStyle(
                                            color: Colors.black),
                                        textConfirm: 'yes'.tr,
                                        textCancel: 'no'.tr,
                                        confirmTextColor: Colors.white,
                                        cancelTextColor: Colors.black,
                                        buttonColor: const Color(0xFF0D2C54),
                                        onConfirm: () {
                                          controller.deleteDepartment(recordId);
                                          Get.back();
                                        },
                                        onCancel: () {
                                          Get.back();
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                )
              ],
            ),

            // Floating "Add Department" button
            Positioned(
              bottom: 40,
              right: 20,
              child: GestureDetector(
                onTap: () {
                  Get.to(() => AddDepartmentScreen());
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D2C54),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: Colors.white),
                      SizedBox(width: 5),
                      Text(
                        "add_department".tr,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Search bar widget
  Widget searchBarContainer(AdminDashboardControllerScreen controller) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D2C54),
        borderRadius: BorderRadius.only(bottomRight: Radius.circular(50)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(
          top: 80,
          right: 20,
          left: 20,
          bottom: 30,
        ),
        child: Row(
          children: [
            const CustomMenuDropdown(),
            const SizedBox(width: 15),
            Expanded(
              child: CustomTextFormField(
                controller: controller.searchController,
                hintText: "search_pgi_department".tr,
                suffixIcon: GestureDetector(
                  onTap: () {
                    controller.searchController.clear();
                  },
                  child: const Icon(
                    Icons.clear,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
