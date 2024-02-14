import 'package:letsspeak/data/repository/user_repository.dart';
import 'package:letsspeak/di/service_locator.dart';
import 'package:letsspeak/ui/dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:firebase_auth/firebase_auth.dart';

import '../../validator.dart';
import '../home/home_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _registerFormKey = GlobalKey<FormState>();

  final _nameTextController = TextEditingController();
  final _emailTextController = TextEditingController();
  final _passwordTextController = TextEditingController();

  final _focusName = FocusNode();
  final _focusEmail = FocusNode();
  final _focusPassword = FocusNode();

  bool _isProcessing = false;

  final userRepository = getIt.get<UserRepository>();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _focusName.unfocus();
        _focusEmail.unfocus();
        _focusPassword.unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.register),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Form(
                  key: _registerFormKey,
                  child: Column(
                    children: <Widget>[
                      TextFormField(
                        controller: _nameTextController,
                        focusNode: _focusName,
                        validator: (value) => Validator.validateName(name: value),
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!.txt_name,
                          errorBorder: UnderlineInputBorder(
                            borderRadius: BorderRadius.circular(6.0),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                        ),

                      ),
                      const SizedBox(height: 16.0),
                      TextFormField(
                        controller: _emailTextController,
                        focusNode: _focusEmail,
                        validator: (value) => Validator.validateEmail(context: context ,email: value),
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!.email,
                          errorBorder: UnderlineInputBorder(
                            borderRadius: BorderRadius.circular(6.0),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      TextFormField(
                        controller: _passwordTextController,
                        focusNode: _focusPassword,
                        obscureText: true,
                        validator: (value) => Validator.validatePassword(password: value),
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!.password,
                          errorBorder: UnderlineInputBorder(
                            borderRadius: BorderRadius.circular(6.0),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32.0),
                      _isProcessing
                          ? const CircularProgressIndicator()
                          : Row(children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _signUp,
                                  child: Text(
                                    AppLocalizations.of(context)!.sign_up,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<User> _createAccount() async {
    UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: _emailTextController.text,
      password: _passwordTextController.text,
    );

    final user = userCredential.user!;
    await user.updateDisplayName(_nameTextController.text);
    await userRepository.addNewUserRequested();
    return user;
  }

  _signUp() async {

    if (_registerFormKey.currentState!.validate()) {
      setState(() {
        _isProcessing = true;
      });

      _createAccount().whenComplete(() {
        setState(() {
          _isProcessing = false;
        });
      }).then((User user) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }, onError: (err) {
        showMyDialog(context, err.message ?? AppLocalizations.of(context)!.unknown_error);
      });
    }
  }
}
