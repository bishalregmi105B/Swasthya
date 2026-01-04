class User {
  final int id;
  final String email;
  final String fullName;
  final String? phone;
  final String? dateOfBirth;
  final String? gender;
  final String? bloodType;
  final String? profileImage;
  final String? city;
  final String? province;
  final bool isVerified;
  final String createdAt;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.dateOfBirth,
    this.gender,
    this.bloodType,
    this.profileImage,
    this.city,
    this.province,
    this.isVerified = false,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'],
      phone: json['phone'],
      dateOfBirth: json['date_of_birth'],
      gender: json['gender'],
      bloodType: json['blood_type'],
      profileImage: json['profile_image'],
      city: json['city'],
      province: json['province'],
      isVerified: json['is_verified'] ?? false,
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      'blood_type': bloodType,
      'profile_image': profileImage,
      'city': city,
      'province': province,
      'is_verified': isVerified,
      'created_at': createdAt,
    };
  }
}
