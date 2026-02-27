import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:indira_love/core/theme/app_theme.dart';
import 'package:indira_love/core/l10n/app_localizations.dart';
import 'package:indira_love/core/l10n/locale_provider.dart';
import 'package:indira_love/core/widgets/app_snackbar.dart';

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.romanticGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    ),
                    Expanded(
                      child: Text(
                        l10n.selectLanguage,
                        style: const TextStyle(
                          fontFamily: 'PlayfairDisplay',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Icon(Icons.language, color: Colors.white, size: 28),
                  ],
                ),
              ),

              // Description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Choose your preferred language. The app will display all text in your selected language.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Language List
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: AppLocalizations.supportedLocales.map((locale) {
                    final isSelected = currentLocale.languageCode == locale.languageCode;
                    final name = AppLocalizations.languageNames[locale.languageCode] ?? locale.languageCode;
                    final nativeName = AppLocalizations.languageNativeNames[locale.languageCode] ?? '';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () {
                          ref.read(localeProvider.notifier).setLocale(locale);
                          AppSnackBar.success(context, '${l10n.languageChanged}: $name');
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withOpacity(0.25)
                                : Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 2)
                                : Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              // Flag/Icon
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.accentGold.withOpacity(0.3)
                                      : Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    nativeName.isNotEmpty ? nativeName.substring(0, 1) : locale.languageCode.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.white : Colors.white70,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      nativeName,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        color: Colors.white60,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 28,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
