import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:swasthya/l10n/generated/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import '../../services/location_service.dart';
import '../../services/api_service.dart';
import '../../models/user.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _provinceController = TextEditingController();

  String? _selectedGender;
  String? _selectedBloodType;
  bool _isLoading = false;
  bool _isDetectingLocation = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _nameController.text = user.fullName;
      _phoneController.text = user.phone ?? '';
      _cityController.text = user.city ?? '';
      _provinceController.text = user.province ?? '';
      _selectedGender = user.gender;
      _selectedBloodType = user.bloodType;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    super.dispose();
  }

  Future<void> _detectLocation() async {
    setState(() => _isDetectingLocation = true);
    try {
      final position = await locationService.getCurrentLocation();
      if (position != null && mounted) {
        setState(() {
          _cityController.text = locationService.currentCity ?? '';
          _provinceController.text = locationService.currentProvince ?? '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '📍 Location detected: ${locationService.getLocationSummary()}'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not detect location. Please enable GPS.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isDetectingLocation = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final updates = {
        'full_name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'city': _cityController.text.trim(),
        'province': _provinceController.text.trim(),
        'gender': _selectedGender,
        'blood_type': _selectedBloodType,
      };

      final response = await apiService.updateProfile(updates);

      // Backend returns user directly, not wrapped in {user: ...}
      if (response['id'] != null && mounted) {
        final updatedUser = User.fromJson(response);
        await context.read<AuthProvider>().updateUser(updatedUser);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.editProfile),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Save',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile Picture
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.primary.withOpacity(0.2),
                      child: Text(
                        _nameController.text.isNotEmpty
                            ? _nameController.text[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          fontSize: 32,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Full Name
              _buildTextField(
                controller: _nameController,
                label: 'Full Name',
                icon: Icons.person_outline,
                validator: (v) =>
                    v?.isEmpty == true ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),

              // Phone
              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              // Gender & Blood Type
              Row(
                children: [
                  Expanded(
                    child: _buildDropdown(
                      value: _selectedGender,
                      label: 'Gender',
                      icon: Icons.person_outline,
                      items: const ['male', 'female', 'other'],
                      displayLabels: const ['Male', 'Female', 'Other'],
                      onChanged: (v) => setState(() => _selectedGender = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDropdown(
                      value: _selectedBloodType,
                      label: 'Blood Type',
                      icon: Icons.bloodtype_outlined,
                      items: const [
                        'A+',
                        'A-',
                        'B+',
                        'B-',
                        'O+',
                        'O-',
                        'AB+',
                        'AB-'
                      ],
                      onChanged: (v) => setState(() => _selectedBloodType = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Location Section Header
              Row(
                children: [
                  const Icon(Icons.location_on,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Location',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _isDetectingLocation ? null : _detectLocation,
                    icon: _isDetectingLocation
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.my_location, size: 16),
                    label: Text(
                        _isDetectingLocation ? 'Detecting...' : 'Detect GPS'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // City
              _buildTextField(
                controller: _cityController,
                label: 'City',
                icon: Icons.location_city_outlined,
                hint: 'e.g., Kathmandu',
              ),
              const SizedBox(height: 16),

              // Province
              _buildTextField(
                controller: _provinceController,
                label: 'Province',
                icon: Icons.map_outlined,
                hint: 'e.g., Bagmati',
              ),
              const SizedBox(height: 32),

              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Changes',
                        style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: Theme.of(context).dividerColor.withOpacity(0.3)),
        ),
        filled: true,
        fillColor: Theme.of(context).cardTheme.color,
      ),
      validator: validator,
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String label,
    required IconData icon,
    required List<String> items,
    List<String>? displayLabels,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: Theme.of(context).dividerColor.withOpacity(0.3)),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          border: InputBorder.none,
          icon: Icon(icon, size: 20),
          contentPadding: EdgeInsets.zero,
        ),
        hint: Text(label),
        items: items
            .asMap()
            .entries
            .map((entry) => DropdownMenuItem(
                value: entry.value,
                child: Text(displayLabels != null
                    ? displayLabels[entry.key]
                    : entry.value)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
