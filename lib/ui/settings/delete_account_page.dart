import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:letsspeak/di/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../data/models/responses/user_data_response.dart';
import '../../data/repository/user_repository.dart';
import '../../validator.dart';
import '../login/login_page.dart';

class DeleteAccountPage extends StatefulWidget {
  final UserDataResponse userData;

  const DeleteAccountPage({super.key, required this.userData});

  @override
  State createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _confirmController = TextEditingController();
  final _confirmFocusNode = FocusNode();
  bool _isProcessing = false;

  final userRepository = getIt.get<UserRepository>();
  final GoogleSignIn _googleSignIn = getIt<GoogleSignIn>();

  @override
  void initState() {
    super.initState();
    _confirmController.text = '';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _confirmFocusNode.unfocus();
      },
      child: Scaffold(
        appBar:
            AppBar(title: Text(AppLocalizations.of(context)!.delete_account)),
        body: Padding(
          padding: const EdgeInsets.only(left: 24.0, right: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: Text(
                  "Are you sure you want to delete your account? Please read how account deletion will affect.",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(
                  "Account",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  "Deleting your account removes personal information from our database. Your email becomes permanently reserved and same email cannot be re-used to register a new account.",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(
                  "Email Subscription",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  "Deleting your account will unsubscribe you from all mailing lists.",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(
                  "Confirm Account Deletion",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  "Enter ${widget.userData.email} to confirm:",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Form(
                key: _formKey,
                child: Column(
                  children: <Widget>[
                    TextFormField(
                      controller: _confirmController,
                      focusNode: _confirmFocusNode,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        errorBorder: UnderlineInputBorder(
                          borderRadius: BorderRadius.circular(6.0),
                          borderSide: const BorderSide(
                            color: Colors.red,
                          ),
                        ),
                      ),
                      validator: (value) {
                        return Validator.validateConfirmDeleteAccount(
                          context: context,
                          email: widget.userData.email,
                          message: value ?? '',
                        );
                      },
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
                                      onPressed: () {
                                        _send();
                                      },
                                      child: Text(
                                          AppLocalizations.of(context)!.delete),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _send() async {
    _confirmFocusNode.unfocus();

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isProcessing = true;
      });

      userRepository.deleteAccount().then((value) {
        FirebaseAuth.instance.signOut().then((value) {
          _googleSignIn.signOut();
          Navigator.of(context).pop();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const LoginPage(),
            ),
          );
        });
      });
    }
  }
}
