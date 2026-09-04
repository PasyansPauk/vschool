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

  static UserProfile sample() {
    return const UserProfile(
      id: 'mesh_usr_94821',
      fullName: 'Николаев Александр Сергеевич',
      className: '10 «А» класс',
      schoolName: 'ГБОУ Школа № 1502 «Энергия»',
      snils: '194-382-901 88',
      mosId: 'ID-8839104-MOS',
      canteenBalance: 650.00,
      isMosIdLinked: true,
    );
  }
}
