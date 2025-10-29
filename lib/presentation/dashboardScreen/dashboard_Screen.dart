import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import '../../widgets/custom_text_form_field.dart';
import '../../widgets/popMenuButton.dart';
import 'controller/dashboard_screen_controller.dart';

class DashBoardScreen extends StatelessWidget {
  const DashBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<DashboardScreenController>()
        ? Get.find<DashboardScreenController>()
        : Get.put(DashboardScreenController());

    final selectedLang = Get.locale?.languageCode ?? 'en';

    return GetBuilder<DashboardScreenController>(
      builder: (controller) => Scaffold(
        body: Column(
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
                            var data = controller.filteredDepartments[index];
                            var nameData = data['name'];

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

                              displayName = controller.getDisplayName(nameData as Map<String, dynamic>, selectedLang);

                              // Auto translate if needed
                              // if (nameId != null && english != null) {
                              //   controller.autoTranslateAndSave(nameId, english, hindi, punjabi);
                              // }
                            }

                            // Get first image URL
                            String? imageUrl = controller.getFirstImageUrl(data['images']);

                            return GestureDetector(
                              onTap: () {
                                print("data -- $data");
                                // Get.to(() => PgiMapScreen(), arguments: data);
                              },
                              child: Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 6),
                                child: ListTile(
                                  leading: imageUrl != null
                                      ? CircleAvatar(
                                          backgroundColor: Colors.grey[300],
                                          child: ClipOval(
                                            child: Image.network(
                                              imageUrl,
                                              fit: BoxFit.cover,
                                              width: 40,
                                              height: 40,
                                              loadingBuilder: (context, child, loadingProgress) {
                                                if (loadingProgress == null) return child;
                                                return Shimmer.fromColors(
                                                  baseColor: Colors.grey[400]!,
                                                  highlightColor: Colors.grey[100]!,
                                                  child: Container(
                                                    width: 40,
                                                    height: 40,
                                                    color: Colors.white,
                                                  ),
                                                );
                                              },
                                              errorBuilder: (context, error, stackTrace) {
                                                return const Icon(Icons.error, color: Colors.red);
                                              },
                                            ),
                                          ),
                                        )
                                      : const CircleAvatar(child: Icon(Icons.image)),
                                  title: Text(displayName),
                                  subtitle: Text(
                                    "${'room'.tr}: ${data['room_number'] ?? 'N/A'}\n"
                                        "${'floor'.tr}: ${data['floor_number'] ?? 'N/A'}\n"
                                        "${'location'.tr}: ${data['location'] ?? 'N/A'}",
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget searchBarContainer(DashboardScreenController controller) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D2C54),
        borderRadius: BorderRadius.only(bottomRight: Radius.circular(50)),
      ),
      child: Padding(
        padding:
        const EdgeInsets.only(top: 80, right: 20, left: 20, bottom: 30),
        child: Row(
          children: [
            const CustomMenuDropdown(),
            const SizedBox(width: 15),
            Expanded(
              child: CustomTextFormField(
                controller: controller.searchController,
                suffixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFF0D2C54),
                  size: 24,
                ),
                hintText: "search_pgi_department".tr,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
