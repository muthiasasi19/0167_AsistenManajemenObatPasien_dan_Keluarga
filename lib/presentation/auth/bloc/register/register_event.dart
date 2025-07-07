part of 'register_bloc.dart';

sealed class RegisterEvent {}

class RegisterRequested extends RegisterEvent {
  final RegisterRequestModel request;

  RegisterRequested({required this.request});
}
