class UserModel {
  final String id;
  final String name;
  final String position;
  final String email;
  final String? imageUrl;
  final int workedHours;
  final double salary;
  final int availableOffDays;

  UserModel({
    required this.id,
    required this.name,
    required this.position,
    required this.email,
    this.imageUrl,
    required this.workedHours,
    required this.salary,
    required this.availableOffDays,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      position: json['position'] as String,
      email: json['email'] as String,
      imageUrl: json['image_url'] as String?,
      workedHours: json['worked_hours'] as int,
      salary: (json['salary'] as num).toDouble(),
      availableOffDays: json['available_off_days'] as int,
    );
  }
}
