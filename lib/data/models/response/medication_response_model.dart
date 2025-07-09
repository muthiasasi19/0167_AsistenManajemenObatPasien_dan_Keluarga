import 'dart:convert';
import 'dart:developer' as developer;

class MedicationSchedule {
  final String type;
  final List<String>? times;
  final List<String>? daysOfWeek;
  final String? notes;

  MedicationSchedule({
    required this.type,
    this.times,
    this.daysOfWeek,
    this.notes,
  });

  factory MedicationSchedule.fromMap(Map<String, dynamic> map) {
    return MedicationSchedule(
      type: map['type'] as String? ?? 'unknown',
      times: (map['times'] as List<dynamic>?)?.map((e) => e as String).toList(),
      daysOfWeek:
          (map['daysOfWeek'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'times': times,
      'daysOfWeek': daysOfWeek,
      'notes': notes,
    };
  }

  // Helper untuk menampilkan jadwal dengan format yang mudah dibaca di UI
  String get displayString {
    String result = '';
    switch (type) {
      case 'daily_fixed_times':
        if (times != null && times!.isNotEmpty) {
          result = '${times!.length}x sehari (${times!.join(', ')})';
        } else {
          result = 'Harian';
        }
        break;
      case 'specific_days_of_week':
        if (daysOfWeek != null && daysOfWeek!.isNotEmpty) {
          result = 'Setiap ${daysOfWeek!.join(', ')}';
          if (times != null && times!.isNotEmpty) {
            result += ' (${times!.join(', ')})';
          }
        } else {
          result = 'Hari tertentu';
        }
        break;
      case 'as_needed':
        result = 'Sesuai Kebutuhan (PRN)';
        break;
      case 'unknown':
        result = notes ?? 'Jadwal Tidak Diketahui';
        break;
      default:
        result = 'Jadwal Tidak Diketahui';
        break;
    }
    if (type != 'unknown' && notes != null && notes!.isNotEmpty) {
      result += ' - $notes';
    }
    return result;
  }
}
