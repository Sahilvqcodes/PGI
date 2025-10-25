import 'package:chandigarh/localization/en_us/paIN_translation.dart';
import 'package:get/get.dart';
import 'en_us/en_us_translations.dart';
import 'en_us/hiIN_translation.dart';


class AppLocalization extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'en_US': enUS,
    'hi_IN': hiIN,
    'pa_IN' : paIN
  };
}