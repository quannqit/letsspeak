import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:letsspeak/data/repository/user_repository.dart';
import 'package:letsspeak/di/service_locator.dart';
import 'package:letsspeak/ui/dialog.dart';
import 'package:letsspeak/ui/home/home_page.dart';
import 'package:letsspeak/ui/login/google_signIn_button.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:letsspeak/ui/login/register_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../firebase_options.dart';
import '../../validator.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailTextController = TextEditingController();
  final _passwordTextController = TextEditingController();

  final _focusEmail = FocusNode();
  final _focusPassword = FocusNode();

  bool _isProcessing = false;
  bool _skipPassword = false;

  final userRepository = getIt.get<UserRepository>();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _focusEmail.unfocus();
        _focusPassword.unfocus();
      },
      child: Scaffold(
        body: FutureBuilder(
          future: Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return Padding(
                padding: const EdgeInsets.only(left: 24.0, right: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: Text(
                        AppLocalizations.of(context)!.login,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: <Widget>[
                          TextFormField(
                            controller: _emailTextController,
                            focusNode: _focusEmail,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) => Validator.validateEmail(
                              context: context,
                              email: value,
                            ),
                            decoration: InputDecoration(
                              hintText: AppLocalizations.of(context)!.email,
                              errorBorder: UnderlineInputBorder(
                                borderRadius: BorderRadius.circular(6.0),
                                borderSide: const BorderSide(
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          TextFormField(
                            controller: _passwordTextController,
                            focusNode: _focusPassword,
                            keyboardType: TextInputType.visiblePassword,
                            obscureText: true,
                            validator: (value) {
                              if (!_skipPassword) {
                                return Validator.validatePassword(
                                  password: value,
                                );
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              hintText: AppLocalizations.of(context)!.password,
                              errorBorder: UnderlineInputBorder(
                                borderRadius: BorderRadius.circular(6.0),
                                borderSide: const BorderSide(
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24.0),
                          _isProcessing
                              ? const CircularProgressIndicator()
                              : Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: _handleSignIn,
                                            child: Text(
                                              AppLocalizations.of(context)!.sign_in,
                                              style: const TextStyle(color: Colors.white),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 24.0),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: _handleSignUp,
                                            child: Text(
                                              AppLocalizations.of(context)!.register,
                                              style: const TextStyle(color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 24),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(child: GestureDetector(
                                            onTap: _requestResetCode,
                                            child: Text(AppLocalizations.of(context)!.reset_password),
                                          )),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 24),
                                      child: GoogleSignInButton(
                                        onSuccess: (User user) {
                                          return _handleGoogleSignInSuccess(user);
                                        },
                                      ),
                                    ),
                                    Visibility(
                                      visible: Platform.isIOS,
                                      child: SignInWithAppleButton(
                                        borderRadius: const BorderRadius.all(Radius.circular(44.0)),
                                        onPressed: _handleSignInWithApple,
                                      ),
                                    ),
                                  ],
                                ),
                        ],
                      ),
                    )
                  ],
                ),
              );
            }

            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  _handleSignIn() {
    _focusEmail.unfocus();
    _focusPassword.unfocus();
    _skipPassword = false;
    if (_formKey.currentState!.validate()) {

      setState(() {
        _isProcessing = true;
      });

      FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailTextController.text,
        password: _passwordTextController.text,
      ).whenComplete(() {
        setState(() {
          _isProcessing = false;
        });
      }).then((result) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const HomePage()));
      }, onError: (err) {
        showMyDialog(context, err.message ?? AppLocalizations.of(context)!.unknown_error);
      });
    }
  }

  _handleSignUp() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => const RegisterPage()));
  }

  _handleGoogleSignInSuccess(User user) {
    return userRepository.addNewUserRequested().then((value) {
      if (kDebugMode) {
        print('User is created!');
      }
      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const HomePage()));
      }
    });
  }

  _handleSignInWithApple() async {

    /// Generates a cryptographically secure random nonce, to be included in a
    /// credential request.
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    final rawNonce = List.generate(32, (_) => charset[random.nextInt(charset.length)]).join();

    /// Returns the sha256 hash of [input] in hex notation.
    final bytes = utf8.encode(rawNonce);
    final digest = sha256.convert(bytes);
    final nonce = digest.toString();

    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );

    if (kDebugMode) {
      print(credential);
    }

    // Now send the credential (especially `credential.authorizationCode`) to your server to create a session
    // after they have been validated with Apple (see `Integration` section for more information on how to do this)
    // Create an `OAuthCredential` from the credential returned by Apple.

    final oauthCredential = OAuthProvider("apple.com").credential(
      idToken: credential.identityToken,
      rawNonce: rawNonce,
    );

    // Sign in the user with Firebase. If the nonce we generated earlier does
    // not match the nonce in `appleCredential.identityToken`, sign in will fail.
    FirebaseAuth.instance.signInWithCredential(oauthCredential).then((authResult) {
      User user = authResult.user!;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const HomePage()));
    });
  }

  _requestResetCode() {
    _focusEmail.unfocus();
    _focusPassword.unfocus();
    _skipPassword = true;
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isProcessing = true;
      });

      FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailTextController.text,
      ).whenComplete(() {
        setState(() {
          _isProcessing = false;
        });
      }).then((value) {
          showMyDialog(context, AppLocalizations.of(context)!.reset_password_sent);
        },
        onError: (err) {
          showMyDialog(context, err.message ?? AppLocalizations.of(context)!.unknown_error);
        }
      );
    }
  }
}
