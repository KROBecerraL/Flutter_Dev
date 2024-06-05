class User {
  final String image;
  final String name;
  final String email;
  final String phone;
  final String job;

  User(
      {required this.image,
      required this.name,
      required this.email,
      required this.phone,
      required this.job});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
        image: json['image'],
        name: json['name'],
        email: json['email'],
        phone: json['phone'],
        job: json['job']);
  }
}
