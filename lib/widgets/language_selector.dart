import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../notifiers.dart';
import '../services/localization_service.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  String t(String locale, String key) => LocalizationService.t(locale, key);

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleNotifier>().locale;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: PopupMenuButton<String>(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.language, size: 20),
              const SizedBox(width: 4),
              Text(
                locale.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : null,
                ),
              ),
            ],
          ),
        ),
        tooltip: t(locale, 'change_language'),
        onSelected: (language) {
          context.read<LocaleNotifier>().setLocale(language);
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'en',
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'EN',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      t(locale, 'english'),
                      style: TextStyle(
                        fontWeight: locale == 'en'
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: locale == 'en'
                            ? (Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Theme.of(context).primaryColor)
                            : (Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color),
                      ),
                    ),
                  ),
                  if (locale == 'en')
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Theme.of(context).primaryColor,
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
          PopupMenuItem(
            value: 'el',
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'EL',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      t(locale, 'greek'),
                      style: TextStyle(
                        fontWeight: locale == 'el'
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: locale == 'el'
                            ? (Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Theme.of(context).primaryColor)
                            : (Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color),
                      ),
                    ),
                  ),
                  if (locale == 'el')
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Theme.of(context).primaryColor,
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
