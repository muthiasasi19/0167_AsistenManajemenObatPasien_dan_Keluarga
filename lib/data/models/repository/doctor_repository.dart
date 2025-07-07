import 'dart:convert';
import 'dart:developer' as developer;
import 'package:dartz/dartz.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:manajemen_obat/service/service_http_client.dart';
import 'package:manajemen_obat/data/models/response/doctor_response_model.dart';
import 'package:manajemen_obat/data/models/response/patient_response_model.dart';
import 'package:manajemen_obat/data/models/response/login_response_model.dart';

class DoctorRepository {
  final ServiceHttpClient _httpClient;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  DoctorRepository(this._httpClient);
}
