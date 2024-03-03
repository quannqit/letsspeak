import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:letsspeak/di/service_locator.dart';
import 'package:letsspeak/ui/home/home_page.dart';
import 'package:letsspeak/ui/login/login_page.dart';
import 'package:letsspeak/ui/onboarding/onboarding_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Pass all uncaught "fatal" errors from the framework to Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  final remoteConfig = FirebaseRemoteConfig.instance;
  await remoteConfig.setConfigSettings(RemoteConfigSettings(
    fetchTimeout: const Duration(minutes: 1),
    minimumFetchInterval: const Duration(hours: 1),
  ));

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
    return FutureBuilder<String?>(
      future: getToken(), // a previously-obtained Future<String> or null
      builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
        return MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: buildContent(snapshot),
        );
      },
    );
  }

  buildContent(AsyncSnapshot<String?> snapshot) {
    if (needOnboard) {
      return const OnboardingPage();
    }

    if (snapshot.connectionState == ConnectionState.done) {
      if (FirebaseAuth.instance.currentUser != null && snapshot.data != null) {
        return const HomePage();
      } else {
        return const LoginPage();
      }
    }

    return const CircularProgressIndicator();
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
