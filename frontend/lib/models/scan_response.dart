// API Response Models for /api/scan endpoint

class ScanResponse {
  final String status; // "ready_to_in" or "ready_to_out"
  final String userName;
  final String message;
  final int? defaultCost;
  final int? estimatedClassCount;
  final List<TransportPreset>? transportPresets;
  final int? attendanceId;
  final String? clockInAt;
  final bool? externalActive;
  final int? staproStaffId;

  ScanResponse({
    required this.status,
    required this.userName,
    required this.message,
    this.defaultCost,
    this.estimatedClassCount,
    this.transportPresets,
    this.attendanceId,
    this.clockInAt,
    this.externalActive,
    this.staproStaffId,
  });

  factory ScanResponse.fromJson(Map<String, dynamic> json) {
    return ScanResponse(
      status: json['status'] as String,
      userName: json['user_name'] as String,
      message: json['message'] as String,
      defaultCost: json['default_cost'] as int?,
      estimatedClassCount: json['estimated_class_count'] as int?,
      transportPresets: json['transport_presets'] != null
          ? (json['transport_presets'] as List)
              .map((e) => TransportPreset.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      attendanceId: json['attendance_id'] as int?,
      clockInAt: json['clock_in_at'] as String?,
      externalActive: json['external_active'] as bool?,
      staproStaffId: json['stapro_staff_id'] as int?,
    );
  }
}

class TransportPreset {
  final String name;
  final int amount;

  TransportPreset({
    required this.name,
    required this.amount,
  });

  factory TransportPreset.fromJson(Map<String, dynamic> json) {
    return TransportPreset(
      name: json['name'] as String,
      amount: json['amount'] as int,
    );
  }
}
