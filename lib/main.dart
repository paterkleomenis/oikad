import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'notifiers.dart';
import 'screens/registration_screen.dart';
import 'services/config_service.dart';
import 'services/localization_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Try to initialize Supabase if credentials are available
  try {
    ConfigService.validateSecurity();
    await Supabase.initialize(
      url: ConfigService.secureSupabaseUrl,
      anonKey: ConfigService.secureSupabaseAnonKey,
    );
    print('Supabase initialized successfully');
  } catch (e) {
    print('Supabase initialization failed: $e');
    print('App will run without database functionality');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleNotifier()),
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<LocaleNotifier, ThemeNotifier>(
      builder: (context, localeNotifier, themeNotifier, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorSchemeSeed: Colors.teal,
            brightness: Brightness.light,
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorSchemeSeed: Colors.teal,
            brightness: Brightness.dark,
            useMaterial3: true,
          ),
          themeMode: themeNotifier.themeMode,
          locale: Locale(localeNotifier.locale),
          supportedLocales: const [Locale('en'), Locale('el')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const StartScreen(),
        );
      },
    );
  }
}

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<LocaleNotifier, ThemeNotifier>(
      builder: (context, localeNotifier, themeNotifier, child) {
        final locale = localeNotifier.locale;
        final themeMode = themeNotifier.themeMode;

        return Scaffold(
          appBar: AppBar(
            title: Hero(
              tag: 'app-logo',
              child: AnimatedSwitcher(
                duration: ConfigService.normalAnimationDuration,
                child: Image.asset(
                  'assets/oikad-logo.png',
                  height: 50,
                  key: ValueKey(locale),
                ),
              ),
            ),
            centerTitle: true,
            actions: [
              _LanguageToggleButton(
                locale: locale,
                onToggle: () => localeNotifier.toggleLocale(),
              ),
              _ThemeToggleButton(
                themeMode: themeMode,
                locale: locale,
                onToggle: () => themeNotifier.toggleTheme(),
              ),
            ],
          ),
          body: const _StartScreenBody(),
        );
      },
    );
  }
}

class _StartScreenBody extends StatelessWidget {
  const _StartScreenBody();

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleNotifier>(
      builder: (context, localeNotifier, child) {
        final locale = localeNotifier.locale;

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(ConfigService.largePadding * 1.5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Hero(
                  tag: 'app-logo-large',
                  child: AnimatedContainer(
                    duration: ConfigService.slowAnimationDuration,
                    curve: Curves.easeOutCubic,
                    child: Image.asset(
                      'assets/oikad-logo.png',
                      height: 120,
                      key: ValueKey('${locale}_large'),
                    ),
                  ),
                ),
                const SizedBox(height: ConfigService.largePadding * 2),
                AnimatedContainer(
                  duration: ConfigService.normalAnimationDuration,
                  curve: Curves.easeOutCubic,
                  child: _RegisterButton(locale: locale),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RegisterButton extends StatelessWidget {
  final String locale;

  const _RegisterButton({required this.locale});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RegistrationScreen()),
        );
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_add, size: 24),
          const SizedBox(width: 12),
          Text(LocalizationService.t(locale, 'register')),
        ],
      ),
    );
  }
}

class _LanguageToggleButton extends StatelessWidget {
  final String locale;
  final VoidCallback onToggle;

  const _LanguageToggleButton({required this.locale, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: ConfigService.normalAnimationDuration,
      child: IconButton(
        key: ValueKey(locale),
        icon: const Icon(Icons.language),
        tooltip: locale == 'en'
            ? LocalizationService.t(locale, 'greek')
            : LocalizationService.t(locale, 'english'),
        onPressed: onToggle,
      ),
    );
  }
}

class _ThemeToggleButton extends StatelessWidget {
  final ThemeMode themeMode;
  final String locale;
  final VoidCallback onToggle;

  const _ThemeToggleButton({
    required this.themeMode,
    required this.locale,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: ConfigService.normalAnimationDuration,
      child: IconButton(
        key: ValueKey(themeMode),
        icon: Icon(
          themeMode == ThemeMode.light ? Icons.dark_mode : Icons.light_mode,
        ),
        tooltip: themeMode == ThemeMode.light
            ? LocalizationService.t(locale, 'dark')
            : LocalizationService.t(locale, 'light'),
        onPressed: onToggle,
      ),
    );
  }
}
