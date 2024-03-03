import 'package:flutter/cupertino.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class Validator {
  static String? validateName({required BuildContext context, required String? name}) {
    if (name == null) {
      return null;
    }

    if (name.isEmpty) {
      return AppLocalizations.of(context)!.validator_name_empty;
    }

    return null;
  }

  static String? validateEmail({required BuildContext context ,required String? email}) {
    if (email == null) {
      return null;
    }

    RegExp emailRegExp = RegExp(
        r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$");

    if (email.isEmpty) {
      return AppLocalizations.of(context)!.validator_email_empty;
    } else if (!emailRegExp.hasMatch(email)) {
      return AppLocalizations.of(context)!.validator_email_empty;
    }

    return null;
  }

  static String? validatePassword({required BuildContext context, required String? password}) {
    if (password == null) {
      return null;
    }

    if (password.isEmpty) {
      return AppLocalizations.of(context)!.validator_password_empty;
    } else if (password.length < 6) {
      return AppLocalizations.of(context)!.validator_password_length;
    }

    return null;
  }

  static String? validateConfirmDeleteAccount({required BuildContext context, required String email, required String message}) {

    if (message.trim().compareTo(email) != 0) {
      return AppLocalizations.of(context)!.validator_email_incorrect;
    }

    return null;
  }
}