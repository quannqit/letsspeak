import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class GoogleSignInButton extends StatefulWidget {
  final Future<void> Function(User) onSuccess;

  const GoogleSignInButton({super.key, required this.onSuccess});

  @override
  State createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  bool _isSigningIn = false;

  Future<UserCredential> signInWithGoogle() async {

    GoogleSignInAccount? googleUser;
    String? clientId;

    if (kIsWeb) {
      clientId = "632062248862-5ttb75cetvutdqbaa2n5ria1pr66ag38.apps.googleusercontent.com";
    }

    googleUser = await GoogleSignIn(clientId: clientId).signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    // Once signed in, return the UserCredential
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: OutlinedButton(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(Colors.white),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(44),
            ),
          ),
        ),
        onPressed: _isSigningIn
            ? null
            : () async {
                setState(() {
                  _isSigningIn = true;
                });

                try {
                  final userCredential = await signInWithGoogle();
                  final user = userCredential.user!;
                  await widget.onSuccess(user);
                }
                catch (e) {
                  if (kDebugMode) {
                    print(e);
                  }
                } finally {
                  setState(() {
                    _isSigningIn = false;
                  });
                }
              },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Image(
                image: AssetImage("assets/images/google_logo.png"),
                height: 35.0,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Text(
                  AppLocalizations.of(context)!.sign_in_with_google,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
