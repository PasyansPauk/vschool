class UserProfile {
  final String id;
  final String fullName;
  final String className;
  final String schoolName;
  final String snils;
  final String mosId;
  final double canteenBalance;
  final bool isMosIdLinked;
  final String avatarUrl;

  const UserProfile({
    required this.id,
    required this.fullName,
    required this.className,
    required this.schoolName,
    required this.snils,
    required this.mosId,
    required this.canteenBalance,
    required this.isMosIdLinked,
    this.avatarUrl = '',
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
        'avatarUrl': avatarUrl,
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
      avatarUrl: json['avatarUrl'] as String? ?? '',
    );
  }

  factory UserProfile.fromMeshJson(Map<String, dynamic> json) {
    Map<String, dynamic> target = json;
    if (json['payload'] is Map<String, dynamic>) {
      target = json['payload'] as Map<String, dynamic>;
    } else if (json['data'] is Map<String, dynamic>) {
      target = json['data'] as Map<String, dynamic>;
    } else if (json['profile'] is Map<String, dynamic>) {
      target = json['profile'] as Map<String, dynamic>;
    }

    String name = '';
    String className = '';
    String school = '';
    String studentId = '';

    final dynamic childrenRaw =
        target['children'] ?? json['children'] ?? target['payload'] ?? json['payload'];
    if (childrenRaw is List && childrenRaw.isNotEmpty) {
      final child = childrenRaw.first;
      if (child is Map) {
        final fn = child['first_name'] ?? child['firstName'] ?? '';
        final ln = child['last_name'] ?? child['lastName'] ?? '';
        final mn = child['middle_name'] ?? child['middleName'] ?? '';
        name = '$ln $fn $mn'.trim();
        className = (child['class_name'] ?? child['className'] ?? child['class'] ?? '').toString();
        if (child['school'] is Map) {
          school = (child['school']['name'] ??
                  child['school']['short_name'] ??
                  child['school']['full_name'] ??
                  '')
              .toString();
        } else if (child['school_name'] != null) {
          school = child['school_name'].toString();
        }
        studentId = (child['id'] ??
                child['contingent_guid'] ??
                child['student_id'] ??
                child['person_id'] ??
                '')
            .toString();
      }
    }

    if (name.isEmpty) {
      final fn = target['first_name'] ?? target['firstName'] ?? '';
      final ln = target['last_name'] ?? target['lastName'] ?? '';
      final mn = target['middle_name'] ?? target['middleName'] ?? '';
      name = '$ln $fn $mn'.trim();
    }

    if (name.isEmpty) {
      name = (target['fullName'] ??
              target['full_name'] ??
              target['name'] ??
              json['fullName'] ??
              json['name'] ??
              '')
          .toString()
          .trim();
    }

    if (className.isEmpty) {
      className = (target['class_name'] ??
              target['className'] ??
              target['class'] ??
              json['class_name'] ??
              json['className'] ??
              '')
          .toString()
          .trim();
    }

    if (school.isEmpty) {
      if (target['school'] is Map) {
        school = (target['school']['name'] ??
                target['school']['short_name'] ??
                target['school']['full_name'] ??
                '')
            .toString();
      } else {
        school = (target['school_name'] ??
                target['schoolName'] ??
                json['school_name'] ??
                json['schoolName'] ??
                '')
            .toString()
            .trim();
      }
    }

    if (studentId.isEmpty) {
      studentId = (target['id'] ??
              target['profile_id'] ??
              target['student_id'] ??
              target['contingent_guid'] ??
              json['id'] ??
              json['profile_id'] ??
              json['student_id'] ??
              '')
          .toString();
    }

    final balanceNum = (target['balance'] ??
        target['canteenBalance'] ??
        target['account_balance'] ??
        json['balance'] ??
        json['canteenBalance']) as num?;
    final double balance = balanceNum?.toDouble() ?? 0.0;

    String avatarUrl = '';
    final dynamic childrenRaw2 = target['children'] ?? json['children'];
    if (childrenRaw2 is List && childrenRaw2.isNotEmpty) {
       final child = childrenRaw2.first;
       if (child is Map) {
         avatarUrl = (child['avatar_url'] ?? child['photo_url'] ?? '').toString();
       }
    }
    if (avatarUrl.isEmpty) {
       avatarUrl = (target['avatar_url'] ?? target['photo_url'] ?? json['avatar_url'] ?? '').toString();
    }

    return UserProfile(
      id: studentId.isNotEmpty ? studentId : 'mesh_user',
      fullName: name,
      className: className,
      schoolName: school,
      snils: (target['snils'] ?? json['snils'] ?? '').toString(),
      mosId: (target['mos_id'] ??
              target['sps_id'] ??
              json['mos_id'] ??
              json['sps_id'] ??
              'Mos.ID')
          .toString(),
      canteenBalance: balance,
      isMosIdLinked: true,
      avatarUrl: avatarUrl,
    );
  }
}
