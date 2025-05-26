class BaddyUser{
  final String email;
  final String password;
  final String name;
  String groupId;
  late String type;
  late String uid;


  BaddyUser({required this.email, required this.password, this.name = '', this.groupId = '',});
}