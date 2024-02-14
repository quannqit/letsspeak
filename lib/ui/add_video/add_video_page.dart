import 'package:letsspeak/data/repository/video_repository.dart';
import 'package:letsspeak/di/service_locator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../firebase_options.dart';

class AddVideoPage extends StatefulWidget {
  final String videoId;

  const AddVideoPage(this.videoId, {super.key});

  @override
  State createState() => _AddVideoPageState();
}

class _AddVideoPageState extends State<AddVideoPage> {
  final _formKey = GlobalKey<FormState>();

  final _videoIdTextController = TextEditingController();

  final _focusVideoId = FocusNode();

  bool _isProcessing = false;

  final videoRepository = getIt.get<VideoRepository>();

  @override
  void initState() {
    super.initState();
    _videoIdTextController.text = widget.videoId;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _focusVideoId.unfocus();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.add_video)),
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
                        AppLocalizations.of(context)!.add_video,
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                    ),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: <Widget>[
                          TextFormField(
                            controller: _videoIdTextController,
                            focusNode: _focusVideoId,
                            keyboardType: TextInputType.url,
                            decoration: InputDecoration(
                              hintText: AppLocalizations.of(context)!.video_id,
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
                                            onPressed: () {
                                              _send().then((value) => {
                                                    Navigator.of(context).pop()
                                                  });
                                            },
                                            child: Text(
                                        AppLocalizations.of(context)!.submit,
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
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

            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        ),
      ),
    );
  }

  Future<void> _send() async {
    _focusVideoId.unfocus();

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isProcessing = true;
      });

      try {
        await videoRepository.addVideo(_videoIdTextController.text);
      } catch (err) {
        Fluttertoast.showToast(
            msg: err.toString(),
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0
        );
      } finally {
        setState(() {
          _isProcessing = false;
        });
      }

    }
  }
}
