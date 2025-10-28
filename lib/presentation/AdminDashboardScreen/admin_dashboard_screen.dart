import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../widgets/custom_text_form_field.dart';
import '../../widgets/popMenuButton.dart';
import 'add_department_screen.dart';
import 'controller/admin_dashboard_controller_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedLang = Get.locale?.languageCode ?? 'en';
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
                  child: controller.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : controller.filteredDepartments.isEmpty
                          ? const Center(child: Text("No departments found"))
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              itemCount: controller.filteredDepartments.length,
                              itemBuilder: (context, index) {
                                var data =
                                    controller.filteredDepartments[index];
                                var recordId = data['id'].toString();
                                var nameData = data['name'];
                                String displayName = 'Unknown';

                                if (nameData != null && nameData is Map) {
                                  displayName = controller.getDisplayName(
                                      nameData as Map<String, dynamic>,
                                      selectedLang);
                                }

                                // Get first image URL
                                String? imageUrl =
                                    controller.getFirstImageUrl(data['images']);

                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 6),
                                  child: ListTile(
                                    leading: imageUrl != null
                                        ? CircleAvatar(
                                            backgroundImage:
                                                NetworkImage(imageUrl),
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
                                              titlePadding:
                                                  EdgeInsets.only(top: 14),
                                              contentPadding:
                                                  EdgeInsets.all(14),
                                              title: 'delete_department'.tr,
                                              middleText:
                                                  'confirm_delete_department'
                                                      .tr,
                                              titleStyle: const TextStyle(
                                                  color: Colors.black),
                                              middleTextStyle: const TextStyle(
                                                  color: Colors.black),
                                              textConfirm: 'yes'.tr,
                                              textCancel: 'no'.tr,
                                              confirmTextColor: Colors.white,
                                              cancelTextColor: Colors.black,
                                              buttonColor:
                                                  const Color(0xFF0D2C54),
                                              onConfirm: () {
                                                controller
                                                    .deleteDepartment(recordId);
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
