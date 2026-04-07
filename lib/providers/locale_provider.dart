import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKeyAppLang = 'app_lang';

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    Future.microtask(_restoreFromPrefs);
    return const Locale('zh');
  }

  Future<void> _restoreFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKeyAppLang) ?? 'zh';
    final next = code == 'en' ? const Locale('en') : const Locale('zh');
    if (next != state) state = next;
  }

  Future<void> setLocale(Locale locale) async {
    final code = locale.languageCode == 'en' ? 'en' : 'zh';
    state = Locale(code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyAppLang, code);
  }

  Future<void> toggleZhEn() async {
    final next = state.languageCode == 'zh' ? const Locale('en') : const Locale('zh');
    await setLocale(next);
  }
}
