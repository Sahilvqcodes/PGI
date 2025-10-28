import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/custom_loading_container.dart';
import '../../widgets/custom_text_form_field.dart';
import 'controller/add_department_controller_screen.dart';

class AddDepartmentScreen extends StatelessWidget {
  const AddDepartmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<AddDepartmentControllerScreen>()
        ? Get.find<AddDepartmentControllerScreen>()
        : Get.put(AddDepartmentControllerScreen());
    return GetBuilder<AddDepartmentControllerScreen>(
      builder: (controller) => Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              searchBarContainer(controller),
              const SizedBox(height: 40),
              formContainer(controller),
            ],
          ),
        ),
      ),
    );
  }

  Widget searchBarContainer(AddDepartmentControllerScreen controller) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D2C54),
        borderRadius: BorderRadius.only(
          bottomRight: Radius.circular(30),
          bottomLeft: Radius.circular(30),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 80, right: 20, left: 20, bottom: 30),
        child: Stack(
          alignment: Alignment.center,
          children: [
             Text(
              "department_form".tr,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () => Get.back(),
                child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget formContainer(AddDepartmentControllerScreen controller) {
    return Form(
      key: controller.keyDepartment,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextFormField(
              controller: controller.departmentName,
              hintText: "enter_department_name".tr,
              validator: (value) =>
              value == null || value.isEmpty ? "please_enter_department_name".tr : null,
            ),
            const SizedBox(height: 20),
            CustomTextFormField(
              readOnly: true,
              showCursor: false, // Hide the cursor
              controller: controller.location,
              hintText: "",
              prefixIcon: const Icon(Icons.location_on_outlined, color: Color(0xFF0D2C54), size: 20),
              validator: controller.validateLocation,
            ),
            const SizedBox(height: 20),
            CustomTextFormField(
              controller: controller.floorNumber,
              textInputType: TextInputType.number,
              hintText: "enter_floor_number".tr,
              prefixIcon: const Icon(Icons.home, color: Color(0xFF0D2C54), size: 20),
              validator: controller.validateFloorNumber,
            ),
            const SizedBox(height: 20),
            CustomTextFormField(
              controller: controller.roomNumber,
              hintText: "enter_room_number".tr,
              textInputType: TextInputType.number,
              prefixIcon: const Icon(Icons.home, color: Color(0xFF0D2C54), size: 20),
              validator: controller.validateRoomNumber,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 64,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: controller.existingImageUrls.length + controller.images.length + 1,
                itemBuilder: (context, index) {
                  // Display existing images from Supabase
                  if (index < controller.existingImageUrls.length) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Stack(
                        children: [
                          Container(
                            height: 64,
                            width: 74,
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                controller.existingImageUrls[index],
                                height: 64,
                                width: 74,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Center(
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(Icons.error, color: Colors.red),
                                  );
                                },
                              ),
                            ),
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: GestureDetector(
                              onTap: () {
                                controller.removeExistingImage(index);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  // Display newly picked images
                  else if (index < controller.existingImageUrls.length + controller.images.length) {
                    final imageIndex = index - controller.existingImageUrls.length;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Stack(
                        children: [
                          Container(
                            height: 64,
                            width: 74,
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.file(
                                controller.images[imageIndex],
                                height: 64,
                                width: 74,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: GestureDetector(
                              onTap: () {
                                controller.removeNewImage(imageIndex);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  // Add button
                  else {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () => showImagePickerSheet(controller),
                        child: DottedBorder(
                          color: Colors.black,
                          strokeWidth: 1.5,
                          borderType: BorderType.RRect,
                          radius: const Radius.circular(6),
                          dashPattern: const [4, 3],
                          child: const SizedBox(
                            height: 64,
                            width: 74,
                            child: Icon(Icons.add, color: Colors.black),
                          ),
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 30),
            controller.isLoading
                ? const CustomLoadingContainer()
                : CustomElevatedButton(
              text: "save".tr,
              onPressed: () {
                controller.saveDepartment();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void showImagePickerSheet(AddDepartmentControllerScreen controller) {
    showModalBottomSheet(
      context: Get.context!,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Take A Photo", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: Colors.black)),
              onTap: () {
                controller.openCamera();
                Get.back();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Upload From Gallery", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: Colors.black)),
              onTap: () {
                controller.pickImage();
                Get.back();
              },
            ),
          ],
        ),
      ),
    );
  }
}
