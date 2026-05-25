class LoginUserOption {
  const LoginUserOption({
    required this.id,
    required this.userName,
    required this.displayName,
    required this.roles,
  });

  final String id;
  final String userName;
  final String displayName;
  final List<String> roles;

  factory LoginUserOption.fromJson(Map<String, dynamic> json) {
    return LoginUserOption(
      id: json['id']?.toString() ?? '',
      userName: json['userName']?.toString() ?? '',
      displayName:
          json['displayName']?.toString() ?? json['userName']?.toString() ?? '',
      roles: (json['roles'] as List? ?? const [])
          .map((item) => item.toString())
          .toList(),
    );
  }

  String get primaryRole => roles.isEmpty ? 'User' : roles.first;
}
