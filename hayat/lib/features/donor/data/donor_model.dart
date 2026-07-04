class Donor {
  final String id;
  final String donorCode;
  final String fullName;
  final String bloodGroup;
  final String mobile;
  final String email;
  final String city;
  final String? gender;
  final int? age;
  final double? weightKg;
  final double? heightCm;
  final String? medications;
  final String? availability;

  // Location
  final double? latitude;
  final double? longitude;

  // Medical vitals
  final String? bloodPressure; 
  final int? systolicBp;
  final int? diastolicBp;
  final int? pulseRate;
  final double? hemoglobin;

  Donor({
    required this.id,
    required this.donorCode,
    required this.fullName,
    required this.bloodGroup,
    required this.mobile,
    required this.email,
    required this.city,
    this.gender,
    this.age,
    this.weightKg,
    this.heightCm,
    this.medications,
    this.availability,
    this.latitude,
    this.longitude,
    this.bloodPressure,
    this.systolicBp,
    this.diastolicBp,
    this.pulseRate,
    this.hemoglobin,
  });

  factory Donor.fromJson(Map<String, dynamic> json) {
    return Donor(
      id: json['id'] as String,
      donorCode: json['donor_code'] as String,
      fullName: json['full_name'] as String,
      bloodGroup: json['blood_group'] as String,
      mobile: json['mobile'] as String,
      email: json['email'] as String,
      city: json['city'] as String,
      gender: json['gender'] as String?,
      age: json['age'] as int?,
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      heightCm: (json['height_cm'] as num?)?.toDouble(),
      medications: json['medications'] as String?,
      availability: json['availability'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      bloodPressure: json['blood_pressure'] as String?,
      systolicBp: json['systolic_bp'] as int?,
      diastolicBp: json['diastolic_bp'] as int?,
      pulseRate: json['pulse_rate'] as int?,
      hemoglobin: (json['hemoglobin_g_dl'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'donor_code': donorCode,
      'full_name': fullName,
      'blood_group': bloodGroup,
      'mobile': mobile,
      'email': email,
      'city': city,
      'gender': gender,
      'age': age,
      'weight_kg': weightKg,
      'height_cm': heightCm,
      'medications': medications,
      'availability': availability,
      'latitude': latitude,
      'longitude': longitude,
      'blood_pressure': bloodPressure,
      'systolic_bp': systolicBp,
      'diastolic_bp': diastolicBp,
      'pulse_rate': pulseRate,
      'hemoglobin_g_dl': hemoglobin,
    };
  }
}
