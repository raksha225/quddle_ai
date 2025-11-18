import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class LoadProfileEvent extends ProfileEvent {
  const LoadProfileEvent();
}

class RefreshProfileEvent extends ProfileEvent {
  const RefreshProfileEvent();
}

class UpdateProfileEvent extends ProfileEvent {
  final String? name;
  final String? phone;
  final String? profileImageUrl;

  const UpdateProfileEvent({
    this.name,
    this.phone,
    this.profileImageUrl,
  });

  @override
  List<Object?> get props => [name, phone, profileImageUrl];
}

class ClearProfileEvent extends ProfileEvent {
  const ClearProfileEvent();
}