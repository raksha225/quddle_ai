import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utils/routes.dart';
import '../../utils/helpers/storage.dart';
import '../../utils/styles/styles.dart';
import '../../utils/theme/theme.dart';
import '../../utils/constants/colors.dart';
import '../../bloc/Profile/profile_bloc.dart';
import '../../bloc/Profile/profile_event.dart';
import '../../bloc/Profile/profile_state.dart';

class ProfileHomeScreen extends StatelessWidget {
  const ProfileHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: MyTheme.myTheme,
      child: Scaffold(
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: MyColors.navbarGradient
            ),
          ),
          elevation: 0,
          toolbarHeight: 60,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => AppRoutes.goBack(context),
          ),
          title: const Text("Profile", style: TextStyle(color: Colors.white)),
          centerTitle: true,
        ),
        body: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            // Show loaded data if available
            if (state is ProfileLoaded) {
              final user = state.user;
              return _buildProfileContent(context, user.name, user.email, user.phone);
            }

            // Handle error state - show error banner but still display UI
            if (state is ProfileError) {
              return Column(
                children: [
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Error: ${state.message}',
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            context.read<ProfileBloc>().add(const LoadProfileEvent());
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _buildProfileContent(context, 'User', 'Error loading email', null),
                  ),
                ],
              );
            }

            // For initial or loading state, show UI with placeholder/default values
            // This avoids showing loading spinner on first open
            String displayName = 'User';
            String displayEmail = 'Loading...';
            String? displayPhone;

            // If we're loading and have previous data (ProfileUpdating), use that
            if (state is ProfileUpdating) {
              displayName = state.user.name;
              displayEmail = state.user.email;
              displayPhone = state.user.phone;
            }

            return _buildProfileContent(context, displayName, displayEmail, displayPhone);
          },
        ),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, String name, String email, String? phone) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Profile Picture Section
          Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  color: MyColors.greyColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  size: 60,
                  color: MyColors.fadedPrimary,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: MyColors.secondary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add,
                    color: MyColors.textWhite,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          // User Information Fields
          _buildInfoField(context, 'Name', name),
          const SizedBox(height: 20),
          _buildInfoField(context, 'Email', email),
          const SizedBox(height: 20),
          _buildInfoField(
            context,
            'Phone Number',
            phone?.isEmpty ?? true ? 'Not provided' : phone!,
          ),
          const SizedBox(height: 60),
          // Logout Button
          CustomButton(
            text: 'Logout',
            gradient: MyColors.primaryGradient,
            textColor: MyColors.textWhite,
            onPressed: () {
              _showLogoutDialog(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoField(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            color: MyColors.bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: MyColors.secondary,
              width: .2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Logout',
            style: TextStyle(
              color: Color(0xFF1E3A8A),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure you want to logout?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // Clear profile state
                context.read<ProfileBloc>().add(const ClearProfileEvent());
                await SecureStorage.clear();
                AppRoutes.navigateToLogin(context);
              },
              child: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}