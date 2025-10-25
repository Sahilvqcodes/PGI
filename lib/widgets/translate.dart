// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:translator/translator.dart';
//
// class TranslationHelper {
//   static final _translator = GoogleTranslator();
//
//   /// 🔹 Translate text to English, Hindi & Punjabi, and update Firestore document
//   static Future<void> autoTranslateAndSave(
//       DocumentReference docRef,
//       Map<String, dynamic> data,
//       ) async {
//     try {
//       // Check if departmentName is Map or simple string
//       final nameField = data['departmentName'];
//       String originalText = '';
//       if (nameField is Map) {
//         originalText = nameField['en'] ?? '';
//       } else {
//         originalText = nameField?.toString() ?? '';
//       }
//
//       if (originalText.isEmpty) return;
//
//       // Already translated? skip
//       if (nameField is Map &&
//           nameField['en'] != null &&
//           nameField['hi'] != null &&
//           nameField['pa'] != null) {
//         print("✅ Already translated — skipping Firestore update");
//         return;
//       }
//
//       print("🌐 Translating: $originalText ...");
//
//       // Translate to English (optional, useful if original text is not proper English)
//       final english = await _translator.translate(originalText, to: 'en');
//       final hindi = await _translator.translate(originalText, to: 'hi');
//       final punjabi = await _translator.translate(originalText, to: 'pa');
//
//       final updatedName = {
//         'en': english.text,
//         'hi': hindi.text,
//         'pa': punjabi.text,
//       };
//
//       await docRef.update({'departmentName': updatedName});
//
//       print("✅ Firestore updated with English, Hindi & Punjabi translations.");
//     } catch (e) {
//       print("❌ Translation error: $e");
//     }
//   }
// }
