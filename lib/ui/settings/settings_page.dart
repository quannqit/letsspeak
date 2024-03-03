import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:letsspeak/ui/home/choose_language_dropdown.dart';
import 'package:letsspeak/ui/settings/delete_account_page.dart';

import '../../data/models/responses/user_data_response.dart';
import '../../di/service_locator.dart';
import '../home/controller.dart';
import '../login/login_page.dart';

class SettingsPage extends StatefulWidget {

  const SettingsPage({super.key});

  @override
  State<StatefulWidget> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with WidgetsBindingObserver {
  final GoogleSignIn _googleSignIn = getIt<GoogleSignIn>();
  final homeController = getIt<HomeController>();

  UserDataResponse? userData;
  String? firstLanguage;
  Future<void>? _initRemoteData;

  @override
  void initState() {
    _initRemoteData = _loadRemoteData();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settings),
      ),
      backgroundColor: const Color(0xfff6f6f6),
      body: FutureBuilder(
        future: _initRemoteData,
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {

          switch (snapshot.connectionState) {
            case ConnectionState.none:
            case ConnectionState.waiting:
            case ConnectionState.active:
              {
                return const Center(child: CircularProgressIndicator());
              }
            case ConnectionState.done:
              {

                return Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: ListView(
                      children: [
                        _SingleSection(
                          title: AppLocalizations.of(context)!.settings,
                          children: [
                            _CustomListTile(
                              title: AppLocalizations.of(context)!.language,
                              icon: Icons.language,
                              trailing: Text(languages[firstLanguage] ?? ''),
                              onTap: () {
                                showChooseFirstLanguage();
                              },
                            ),
                            _CustomListTile(
                              title: AppLocalizations.of(context)!.logout,
                              icon: Icons.logout,
                              onTap: () async {
                                await _googleSignIn.signOut();
                                FirebaseAuth.instance.signOut().then((value) {
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                      builder: (context) => const LoginPage(),
                                    ), (route) => false
                                  );
                                });
                              },
                            ),
                          ],
                        ),
                        _SingleSection(
                          title: AppLocalizations.of(context)!.account,
                          children: [
                            _CustomListTile(
                              title: AppLocalizations.of(context)!.delete_account,
                              icon: Icons.delete,
                              trailing: const Icon(CupertinoIcons.forward, size: 18),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => DeleteAccountPage(userData: userData!),
                                  ),
                                );
                              },
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }
          }
        },
      ),
    );
  }

  showChooseFirstLanguage() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return WillPopScope(
          onWillPop: () => Future.value(false),
          child: AlertDialog(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(20.0),
              ),
            ),
            contentPadding: const EdgeInsets.only(top: 10.0),
            title: Text(
              AppLocalizations.of(context)!.choose_first_language,
              style: const TextStyle(fontSize: 24.0),
            ),
            content: SizedBox(
              child: ChooseLanguageDropdown(
                onSelect: (String lang) {
                  if (kDebugMode) {
                    print("lang: $lang");
                  }
                  homeController.setLanguage(lang).then((value) {
                    setState(() {
                      firstLanguage = lang;
                    });
                  });
                },
                dropdownValue: firstLanguage,
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void>? _loadRemoteData() async {
    userData = await homeController.getUserDataApi();
    setState(() {
      firstLanguage = userData?.firstLanguage;
    });
  }
}

class _CustomListTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget? trailing;
  final GestureTapCallback? onTap;

  const _CustomListTile(
      {Key? key, required this.title, required this.icon, this.trailing, this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      leading: Icon(icon),
      trailing: trailing,
      onTap: onTap ?? () {},
    );
  }
}

class _SingleSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SingleSection({
    Key? key,
    required this.title,
    required this.children,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title.toUpperCase(),
            style:
            Theme
                .of(context)
                .textTheme
                .displaySmall
                ?.copyWith(fontSize: 16),
          ),
        ),
        Container(
          width: double.infinity,
          color: Colors.white,
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}
