// lib/data/models/repository/family_repository.dart
import 'dart:convert';
import 'dart:developer';
import 'package:dartz/dartz.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:manajemen_obat/service/service_http_client.dart';
import 'package:manajemen_obat/data/models/response/connect_patient_family_response_model.dart';
import 'package:manajemen_obat/data/models/response/medication_response_model.dart';
import 'package:manajemen_obat/data/models/response/medication_history_response_model.dart';
import 'package:manajemen_obat/data/models/response/patient_location_response_model.dart';
import 'package:manajemen_obat/data/models/request/connect_patient_family_request_model.dart';

class FamilyRepository {
  final ServiceHttpClient _httpClient;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  FamilyRepository(this._httpClient);

  // Helper untuk mendapatkan ID internal keluarga dari local storage
  Future<int?> _getFamilyGlobalIdFromLocalStorage() async {
    final userDataString = await _secureStorage.read(key: 'userData');
    if (userDataString != null) {
      final userData = jsonDecode(userDataString);
      return userData['familyGlobalId'] as int?;
    }
    return null;
  }
}
