import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_strings.dart';
import 'locale_provider.dart';

final appStringsProvider = Provider<AppStrings>((ref) {
  final locale = ref.watch(localeProvider);
  return locale.languageCode == 'en' ? AppStringsEn() : AppStringsZh();
});
