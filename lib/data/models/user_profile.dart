class UserProfile {
  final String id;
  final String fullName;
  final String className;
  final String schoolName;
  final String snils;
  final String mosId;
  final double canteenBalance;
  final bool isMosIdLinked;

  const UserProfile({
    required this.id,
    required this.fullName,
    required this.className,
    required this.schoolName,
    required this.snils,
    required this.mosId,
    required this.canteenBalance,
    required this.isMosIdLinked,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'className': className,
        'schoolName': schoolName,
        'snils': snils,
        'mosId': mosId,
        'canteenBalance': canteenBalance,
        'isMosIdLinked': isMosIdLinked,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      className: json['className'] as String? ?? '',
      schoolName: json['schoolName'] as String? ?? '',
      snils: json['snils'] as String? ?? '',
      mosId: json['mosId'] as String? ?? '',
      canteenBalance: (json['canteenBalance'] as num?)?.toDouble() ?? 0.0,
      isMosIdLinked: json['isMosIdLinked'] as bool? ?? false,
    );
  }

  factory UserProfile.fromMeshJson(Map<String, dynamic> json) {
    String name = '';
    String className = '';
    String school = '';
    String studentId = '';

    if (json.containsKey('children') &&
        json['children'] is List &&
        (json['children'] as List).isNotEmpty) {
      final child = (json['children'] as List).first as Map<String, dynamic>;
      final fn = child['first_name'] ?? '';
      final ln = child['last_name'] ?? '';
      final mn = child['middle_name'] ?? '';
      name = '$ln $fn $mn'.trim();
      className = (child['class_name'] ?? child['className'] ?? '').toString();
      if (child['school'] is Map) {
        school = (child['school']['name'] ?? child['school']['short_name'] ?? '')
            .toString();
      }
      studentId = (child['id'] ?? child['contingent_guid'] ?? '').toString();
    } else {
      final fn = json['first_name'] ?? json['firstName'] ?? '';
      final ln = json['last_name'] ?? json['lastName'] ?? '';
      final mn = json['middle_name'] ?? json['middleName'] ?? '';
      name = '$ln $fn $mn'.trim();
      className = (json['class_name'] ?? json['className'] ?? '').toString();
      school = (json['school_name'] ?? json['schoolName'] ?? '').toString();
      studentId = (json['id'] ?? json['profile_id'] ?? '').toString();
    }

    if (name.isEmpty) {
      name = (json['fullName'] ?? json['name'] ?? 'Ученик МЭШ').toString();
    }

    return UserProfile(
      id: studentId.isNotEmpty ? studentId : 'mesh_user',
      fullName: name,
      className: className,
      schoolName: school,
      snils: (json['snils'] ?? '').toString(),
      mosId: (json['mos_id'] ?? json['sps_id'] ?? 'Mos.ID').toString(),
      canteenBalance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      isMosIdLinked: true,
    );
  }
}
