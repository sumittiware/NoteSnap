class AppUser {
  String uid;
  String email;
  bool isSelected;

  AppUser({
    required this.uid,
    required this.email,
    this.isSelected = false,
  });

  factory AppUser.fromJson(json) {
    return AppUser(
      uid: json['uid'],
      email: json['email'],
    );
  }
}
