import 'dart:convert';

class AddNotificationScheduleRequestModel {
  final int medicationId;
  final int patientGlobalId;
  final String scheduleTime; // Format HH:MM
  final String startDate; // Format YYYY-MM-DD
  final String? endDate; // Format YYYY-MM-DD, nullable
  final bool isActive;
  final List<int> recipientFamilyIds; // List of global family IDs

  AddNotificationScheduleRequestModel({
    required this.medicationId,
    required this.patientGlobalId,
    required this.scheduleTime,
    required this.startDate,
    this.endDate,
    required this.isActive,
    required this.recipientFamilyIds,
  });

  Map<String, dynamic> toMap() {
    return {
      'medicationId': medicationId,
      'patientGlobalId': patientGlobalId,
      'scheduleTime': scheduleTime,
      'startDate': startDate,
      'endDate': endDate,
      'isActive': isActive,
      'recipientFamilyIds': recipientFamilyIds,
    };
  }

  String toJson() => json.encode(toMap());
}
