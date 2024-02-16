import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:letsspeak/di/service_locator.dart';
import 'package:letsspeak/ui/home/home_page.dart';
import 'package:letsspeak/ui/login/login_page.dart';
import 'package:letsspeak/ui/onboarding/onboarding_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // To load the .env file contents into dotenv.
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Pass all uncaught "fatal" errors from the framework to Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  await setup();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State createState() => _MyApp();
}

class _MyApp extends State<MyApp> {
  late bool needOnboard;

  @override
  void initState() {
    super.initState();
    final prefs = getIt<SharedPreferences>();
    needOnboard = prefs.getBool('needOnboard') ?? true;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: FutureBuilder<String?>(
          future: getToken(), // a previously-obtained Future<String> or null
          builder: (BuildContext context, AsyncSnapshot<String?> token) {
            return MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: needOnboard
                  ? const OnboardingPage()
                  : ((token.data == null)
                      ? const LoginPage()
                      : const HomePage()),
            );
          },
        ));
  }

  Future<String?> getToken() async {
    String? token;
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        token = await user.getIdToken();
      } on FirebaseAuthException {
        FirebaseAuth.instance.signOut();
      }
    }
    return token;
  }
}
