import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:swasthya/l10n/generated/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import '../../services/location_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ageController = TextEditingController();
  final _locationController = TextEditingController();

  bool _obscurePassword = true;
  bool _agreedToTerms = false;
  String _selectedLanguage = 'en';
  String _selectedRole = 'patient'; // patient or doctor
  bool _isDetectingLocation = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _ageController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _detectLocation() async {
    setState(() => _isDetectingLocation = true);
    try {
      final position = await locationService.getCurrentLocation();
      if (position != null && mounted) {
        final locationSummary = locationService.getLocationSummary();
        setState(() {
          _locationController.text = locationSummary;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📍 Location detected: $locationSummary'),
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

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to terms')),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(
      _emailController.text.trim(),
      _passwordController.text,
      _nameController.text.trim(),
      age: int.tryParse(_ageController.text),
      location: _locationController.text.trim(),
      language: _selectedLanguage,
      role: _selectedRole,
    );

    if (success && mounted) {
      context.go('/home');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.error),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.2),
                          AppColors.primary.withOpacity(0.05)
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.medical_services,
                        color: AppColors.primary, size: 36),
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  l10n.signup,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),

                Text(
                  l10n.welcomeSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withOpacity(0.6),
                  ),
                ),

                const SizedBox(height: 24),

                // Full Name
                _buildTextField(
                  controller: _nameController,
                  label: l10n.fullName,
                  icon: Icons.person_outline,
                  validator: (v) =>
                      v?.isEmpty == true ? 'Name is required' : null,
                ),

                const SizedBox(height: 14),

                // Email
                _buildTextField(
                  controller: _emailController,
                  label: l10n.email,
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v?.isEmpty == true) return 'Email is required';
                    if (!v!.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),

                const SizedBox(height: 14),

                // Age & Language Row
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _ageController,
                        label: 'Age',
                        icon: Icons.calendar_today,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Theme.of(context)
                                  .dividerColor
                                  .withOpacity(0.2)),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _selectedLanguage,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            icon: Icon(Icons.translate, size: 20),
                            contentPadding: EdgeInsets.zero,
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'en', child: Text('English')),
                            DropdownMenuItem(
                                value: 'ne', child: Text('Nepali')),
                          ],
                          onChanged: (v) =>
                              setState(() => _selectedLanguage = v ?? 'en'),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Location with GPS detect button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _locationController,
                        label: 'Location',
                        icon: Icons.location_on_outlined,
                        hint: 'City, Province',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: ElevatedButton(
                        onPressed:
                            _isDetectingLocation ? null : _detectLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.all(14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isDetectingLocation
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.my_location,
                                color: Colors.white, size: 22),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Role Selection
                Text(
                  'I am joining as a...',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                        child:
                            _buildRoleCard('patient', 'Patient', Icons.person)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _buildRoleCard(
                            'doctor', 'Doctor', Icons.medical_services)),
                  ],
                ),

                const SizedBox(height: 14),

                // Password
                _buildTextField(
                  controller: _passwordController,
                  label: l10n.password,
                  icon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        size: 20),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (v) {
                    if (v?.isEmpty == true) return 'Password is required';
                    if (v!.length < 6) return 'Min 6 characters';
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // Terms checkbox
                Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _agreedToTerms,
                        onChanged: (v) =>
                            setState(() => _agreedToTerms = v ?? false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text:
                              'I agree to share my health data securely in accordance with the ',
                          style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color
                                  ?.withOpacity(0.6)),
                          children: [
                            TextSpan(
                              text: 'Privacy Policy',
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Submit Button
                ElevatedButton(
                  onPressed: authProvider.isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: authProvider.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Create Account',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                ),

                const SizedBox(height: 16),

                // Divider
                Row(
                  children: [
                    Expanded(
                        child: Divider(color: Theme.of(context).dividerColor)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('Or join with',
                          style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color
                                  ?.withOpacity(0.5))),
                    ),
                    Expanded(
                        child: Divider(color: Theme.of(context).dividerColor)),
                  ],
                ),

                const SizedBox(height: 16),

                // Social buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Apple Sign-In coming soon')),
                          );
                        },
                        icon: const Icon(Icons.apple, size: 20),
                        label: const Text('Apple'),
                        style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 44)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: authProvider.isLoading
                            ? null
                            : () async {
                                final success = await context
                                    .read<AuthProvider>()
                                    .signInWithGoogle();
                                if (success && context.mounted) {
                                  context.go('/home');
                                } else if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(l10n.error),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              },
                        icon: Image.network(
                          'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                          height: 18,
                          width: 18,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.g_mobiledata, size: 24),
                        ),
                        label: const Text('Google'),
                        style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 44)),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // HIPAA badge
                Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_user,
                            color: Colors.green, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'HIPAA Compliant & Secure',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
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
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: suffixIcon,
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

  Widget _buildRoleCard(String value, String label, IconData icon) {
    final isSelected = _selectedRole == value;

    return GestureDetector(
      onTap: () => setState(() => _selectedRole = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.05)
              : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : Theme.of(context).dividerColor.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: isSelected
                    ? AppColors.primary
                    : Theme.of(context).iconTheme.color?.withOpacity(0.5),
                size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isSelected
                    ? AppColors.primary
                    : Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
