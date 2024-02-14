class UserDataResponse {
  UserDataResponse({
    required this.name,
    required this.picture,
    required this.iss,
    required this.aud,
    required this.authTime,
    required this.userId,
    required this.sub,
    required this.iat,
    required this.exp,
    required this.email,
    required this.emailVerified,
    required this.firebase,
    required this.uid,
    required this.id,
    required this.isAdmin,
    this.firstLanguage,
  });
  late final String name;
  late final String picture;
  late final String iss;
  late final String aud;
  late final int authTime;
  late final String userId;
  late final String sub;
  late final int iat;
  late final int exp;
  late final String email;
  late final bool emailVerified;
  late final Firebase firebase;
  late final String uid;
  late final int id;
  late final bool isAdmin;
  String? firstLanguage;

  UserDataResponse.fromJson(Map<String, dynamic> json){
    if (json.containsKey('name')) {
      name = json['name'];
    }
    if (json.containsKey('picture')) {
      picture = json['picture'];
    }
    iss = json['iss'];
    aud = json['aud'];
    authTime = json['auth_time'];
    userId = json['user_id'];
    sub = json['sub'];
    iat = json['iat'];
    exp = json['exp'];
    email = json['email'];
    emailVerified = json['email_verified'];
    firebase = Firebase.fromJson(json['firebase']);
    uid = json['uid'];
    id = json['id'];
    isAdmin = json['isAdmin'];
    if (json.containsKey('firstLanguage')) {
      firstLanguage = json['firstLanguage'];
    }
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['name'] = name;
    _data['picture'] = picture;
    _data['iss'] = iss;
    _data['aud'] = aud;
    _data['auth_time'] = authTime;
    _data['user_id'] = userId;
    _data['sub'] = sub;
    _data['iat'] = iat;
    _data['exp'] = exp;
    _data['email'] = email;
    _data['email_verified'] = emailVerified;
    _data['firebase'] = firebase.toJson();
    _data['uid'] = uid;
    _data['id'] = id;
    _data['isAdmin'] = isAdmin;
    if (firstLanguage != null) {
      _data['firstLanguage'] = firstLanguage;
    }
    return _data;
  }
}

class Firebase {
  Firebase({
    required this.identities,
    required this.signInProvider,
  });
  late final Identities identities;
  late final String signInProvider;

  Firebase.fromJson(Map<String, dynamic> json){
    identities = Identities.fromJson(json['identities']);
    signInProvider = json['sign_in_provider'];
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['identities'] = identities.toJson();
    _data['sign_in_provider'] = signInProvider;
    return _data;
  }
}

class Identities {
  Identities({
    required this.google_com,
    required this.email,
  });
  late final List<String> google_com;
  late final List<String> email;

  Identities.fromJson(Map<String, dynamic> json){
    if (json.containsKey('google.com')) {
      google_com = List.castFrom<dynamic, String>(json['google.com']);
    }
    email = List.castFrom<dynamic, String>(json['email']);
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['google.com'] = google_com;
    _data['email'] = email;
    return _data;
  }
}