import 'package:flutter/foundation.dart';
import 'package:hackathon_net/core/localization/app_language.dart';

class LanguageController extends ChangeNotifier {
  LanguageController([this._language = AppLanguage.en]);

  AppLanguage _language;

  AppLanguage get language => _language;

  void setLanguage(AppLanguage language) {
    if (_language == language) {
      return;
    }
    _language = language;
    notifyListeners();
  }
}
