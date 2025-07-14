import 'dart:convert';

class UpdateNotificationScheduleRequestModel {
  final int? medicationId; // Nullable, as not all fields might be updated
  final int? patientGlobalId;
  final String? scheduleTime;
  final String? startDate;
  final String? endDate;
  final bool? isActive;
  final List<int>? recipientFamilyIds;

  UpdateNotificationScheduleRequestModel({
    this.medicationId,
    this.patientGlobalId,
    this.scheduleTime,
    this.startDate,
    this.endDate,
    this.isActive,
    this.recipientFamilyIds,
  });

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = {};
    if (medicationId != null) map['medicationId'] = medicationId;
    if (patientGlobalId != null) map['patientGlobalId'] = patientGlobalId;
    if (scheduleTime != null) map['scheduleTime'] = scheduleTime;
    if (startDate != null) map['startDate'] = startDate;
    if (endDate != null) map['endDate'] = endDate;
    if (isActive != null) map['isActive'] = isActive;
    if (recipientFamilyIds != null)
      map['recipientFamilyIds'] = recipientFamilyIds;
    return map;
  }

  String toJson() => json.encode(toMap());
}
