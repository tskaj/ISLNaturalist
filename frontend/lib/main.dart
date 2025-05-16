import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'providers/auth_provider.dart';
import 'providers/language_provider.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/new_login_screen.dart'; // <-- Add this line
import 'screens/new_register_screen.dart'; // <-- Add this line
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/disease_service.dart'; // Import DiseaseService
import 'screens/home_screen.dart';
import 'screens/community_screen.dart';
import 'screens/image_picker_screen.dart';
import 'screens/language_selection_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (ctx) => AuthProvider()),
        ChangeNotifierProvider(create: (ctx) => LanguageProvider()),
      ],
      child: Consumer<LanguageProvider>(
        builder: (ctx, languageProvider, _) {
          return MaterialApp(
            title: 'BioScout Islamabad',
            theme: AppTheme.lightTheme,
            locale: languageProvider.locale,
            supportedLocales: const [
              Locale('en', ''), // English
              Locale('ur', ''), // Urdu
            ],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Consumer<LanguageProvider>(
              builder: (ctx, languageProvider, _) {
                // Check if language has been selected
                if (languageProvider.isLanguageSelected) {
                  return const MainNavigationScreen();
                } else {
                  return const LanguageSelectionScreen();
                }
              },
            ),
            routes: {
              '/login': (context) => const NewLoginScreen(),
              '/register': (context) => const NewRegisterScreen(),
              '/home': (ctx) => const HomeScreen(),
              '/community': (ctx) => const CommunityScreen(),
              '/image-picker': (ctx) => const ImagePickerScreen(),
            },
          );
        },
      ),
    );
  }
}
