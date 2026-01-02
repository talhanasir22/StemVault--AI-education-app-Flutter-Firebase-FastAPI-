abstract class User {
  String userID;
  String username;
  String passwordHash;
  String email;
  DateTime createdAt;

  User({
    required this.userID,
    required this.username,
    required this.passwordHash,
    required this.email,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'userID': userID,
      'username': username,
      'passwordHash': passwordHash,
      'email': email,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  User.fromJson(Map<String, dynamic> json)
    : userID = json['userID'],
      username = json['username'],
      passwordHash = json['passwordHash'],
      email = json['email'],
      createdAt = DateTime.parse(json['createdAt']);
}
