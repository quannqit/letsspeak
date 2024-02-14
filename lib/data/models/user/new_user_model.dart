class NewUser {
  int? id;
  String? uid;
  String? name;
  String? createdAt;
  String? updatedAt;

  NewUser({this.name, this.uid, this.id, this.createdAt, this.updatedAt});

  NewUser.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    uid = json['uid'];
    id = json['id'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['uid'] = uid;
    data['id'] = id;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    return data;
  }
}
