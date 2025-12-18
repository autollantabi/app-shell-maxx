enum UserType { admin, manager, influencer }

class UserModel {
  final String id;
  final String name;
  final String email;
  final UserType type;
  final int? roleId; // ROLE_ID original de la API (1=Manager, 2=Vendedor, 3=Influenciador)
  final String? profileImage;
  final String? cedula;
  final DateTime? dateOfBirth;
  final String? phone;
  final String? address;
  final String? managerId; // ID del manager que gestiona este influencer
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.type,
    this.roleId,
    this.profileImage,
    this.cedula,
    this.dateOfBirth,
    this.phone,
    this.address,
    this.managerId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Manejar campos en mayúsculas (API) y minúsculas (legacy)
    final id = json['ID'] ?? json['id'] ?? '';
    final name = (json['NAME'] ?? json['name'] ?? '').toString();
    final lastName = (json['LASTNAME'] ?? json['lastName'] ?? '').toString();
    final fullName = lastName.isNotEmpty ? '$name $lastName' : name;
    final email = json['EMAIL'] ?? json['email'] ?? '';
    final cardId = json['CARD_ID'] ?? json['cardId'] ?? json['cedula'];
    final phone = json['PHONE'] ?? json['phone'];
    final birthDate = json['BIRTH_DATE'] ?? json['birthDate'] ?? json['dateOfBirth'];
    final roleId = json['ROLE_ID'] ?? json['roleId'] ?? json['type'];
    
    // Mapear ROLE_ID a UserType y guardar el ROLE_ID original
    int? roleIdInt;
    if (roleId != null) {
      roleIdInt = roleId is int ? roleId : int.tryParse(roleId.toString());
    }

    UserType userType = UserType.influencer;
    if (roleIdInt != null) {
      if (roleIdInt == 1) {
        userType = UserType.manager; // 1 = MANAGER
      } else if (roleIdInt == 2) {
        userType = UserType.admin; // 2 = VENDEDOR (mapeado a admin temporalmente)
      } else if (roleIdInt == 3) {
        userType = UserType.influencer; // 3 = INFLUENCIADOR
      }
    } else if (json['type'] != null) {
      // Fallback al formato legacy
      userType = UserType.values.firstWhere(
        (e) => e.toString() == 'UserType.${json['type']}',
        orElse: () => UserType.influencer,
      );
    }

    return UserModel(
      id: id,
      name: fullName,
      email: email,
      type: userType,
      roleId: roleIdInt,
      profileImage: json['PERFIL_IMAGE_URL'] ?? json['perfil_image_url'] ?? json['profileImage'],
      cedula: cardId,
      dateOfBirth: birthDate != null ? DateTime.parse(birthDate.toString()) : null,
      phone: phone,
      address: json['address'] ?? json['ADDRESS'],
      managerId: json['managerId'] ?? json['MANAGER_ID'],
      createdAt: DateTime.parse(
        json['createdAt'] ?? json['CREATED_AT'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? json['UPDATED_AT'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'type': type.toString().split('.').last,
      'roleId': roleId,
      'profileImage': profileImage,
      'cedula': cedula,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'phone': phone,
      'address': address,
      'managerId': managerId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    UserType? type,
    int? roleId,
    String? profileImage,
    String? cedula,
    DateTime? dateOfBirth,
    String? phone,
    String? address,
    String? managerId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      type: type ?? this.type,
      roleId: roleId ?? this.roleId,
      profileImage: profileImage ?? this.profileImage,
      cedula: cedula ?? this.cedula,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      managerId: managerId ?? this.managerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get displayName => name.isNotEmpty ? name : email;

  bool get isAdmin => type == UserType.admin;
  bool get isManager => type == UserType.manager;
  bool get isInfluencer => type == UserType.influencer;

  // Métodos basados en ROLE_ID directo
  bool get isManagerByRole => roleId == 1;
  bool get isVendedorByRole => roleId == 2;
  bool get isInfluenciadorByRole => roleId == 3;
}
