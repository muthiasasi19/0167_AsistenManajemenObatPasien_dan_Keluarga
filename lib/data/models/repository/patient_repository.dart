import 'dart:convert';
import 'dart:developer' as developer;
import 'package:dartz/dartz.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:manajemen_obat/service/service_http_client.dart';
import 'package:manajemen_obat/data/models/response/patient_response_model.dart';
import 'package:manajemen_obat/data/models/response/patient_search_result_model.dart';
import 'package:manajemen_obat/data/models/response/doctor_response_model.dart';

class PatientRepository {
  final ServiceHttpClient _httpClient;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  PatientRepository(this._httpClient);

  Future<String?> _getDoctorIdFromLocalStorage() async {
    final userDataString = await _secureStorage.read(key: 'userData');
    if (userDataString != null) {
      final userData = jsonDecode(userDataString);
      return userData['id_dokter']?.toString();
    }
    return null;
  }
}
