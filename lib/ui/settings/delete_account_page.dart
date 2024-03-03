import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:letsspeak/data/repository/auth_repository.dart';
import 'package:letsspeak/di/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../data/models/responses/user_data_response.dart';
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

  final authRepository = getIt.get<AuthRepository>();
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
                  AppLocalizations.of(context)!.delete_account_line1,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(
                  AppLocalizations.of(context)!.account,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  AppLocalizations.of(context)!.delete_account_line2,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(
                  AppLocalizations.of(context)!.email_subscription,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  AppLocalizations.of(context)!.delete_account_line3,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(
                  AppLocalizations.of(context)!.confirm_account_deletion,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  AppLocalizations.of(context)!.delete_account_line4(widget.userData.email),
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

      authRepository.deleteAccount().then((value) async {
        await _googleSignIn.signOut();
        FirebaseAuth.instance.signOut().then((value)  {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const LoginPage(),
            ), (route) {
            return false;
          });
        });
      });
    }
  }
}
