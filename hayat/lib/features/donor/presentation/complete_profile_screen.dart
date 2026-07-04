import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';

import '../../../core/theme/app_theme.dart';
import '../../../core/presentation/widgets/premium_background.dart';
import '../../auth/data/auth_repository.dart';
import '../data/donor_model.dart';
import '../data/donor_repository.dart';

class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _medsController = TextEditingController();
  
  String? _selectedBloodGroup;
  String? _selectedGender;
  String? _availability = 'Anytime';
  
  // Location
  double? _latitude;
  double? _longitude;
  String _locationStatus = "Tap to set your location";
  
  bool _isLoading = false;

  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  final List<String> _genders = ['Male', 'Female'];
  final List<String> _availabilityOptions = ['Anytime', 'Weekends Only', 'Evenings Only', 'Emergency Only'];

  // Predefined locations for Jordan (since we can't use GPS in web easily)
  final Map<String, Map<String, double>> _jordanLocations = {
    'Amman': {'lat': 31.9454, 'lng': 35.9284},
    'Irbid': {'lat': 32.5568, 'lng': 35.8469},
    'Zarqa': {'lat': 32.0728, 'lng': 36.0880},
    'Aqaba': {'lat': 29.5267, 'lng': 35.0078},
    'Salt': {'lat': 32.0392, 'lng': 35.7272},
    'Madaba': {'lat': 31.7160, 'lng': 35.7939},
    'Jerash': {'lat': 32.2747, 'lng': 35.8961},
    'Mafraq': {'lat': 32.3422, 'lng': 36.2083},
  };

  String _generateDonorCode() {
    final random = Random();
    final number = 1000 + random.nextInt(9000);
    return 'DON-$number';
  }

  void _showLocationPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Select Your City", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            Text("This helps us find nearby blood requests.", style: GoogleFonts.inter(color: Colors.grey)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _jordanLocations.keys.map((city) {
                final isSelected = _cityController.text == city;
                return ChoiceChip(
                  label: Text(city),
                  selected: isSelected,
                  onSelected: (v) {
                    setState(() {
                      _cityController.text = city;
                      _latitude = _jordanLocations[city]!['lat'];
                      _longitude = _jordanLocations[city]!['lng'];
                      _locationStatus = "📍 $city";
                    });
                    Navigator.pop(ctx);
                  },
                  selectedColor: AppTheme.primaryRed,
                  backgroundColor: Colors.white10,
                  labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedBloodGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all required fields"), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user == null) throw "No user found";

      final donor = Donor(
        id: user.id,
        donorCode: _generateDonorCode(),
        fullName: _nameController.text.trim(),
        bloodGroup: _selectedBloodGroup!,
        mobile: _phoneController.text.trim(),
        email: user.email ?? "",
        city: _cityController.text.trim(),
        gender: _selectedGender,
        age: int.tryParse(_ageController.text),
        weightKg: double.tryParse(_weightController.text),
        heightCm: double.tryParse(_heightController.text),
        medications: _medsController.text.trim().isEmpty ? null : _medsController.text.trim(),
        availability: _availability,
        latitude: _latitude,
        longitude: _longitude,
      );

      await ref.read(donorRepositoryProvider).createDonorProfile(donor);
      
      if (mounted) {
        context.go('/donor-home');
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("Complete Your Profile", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          const PremiumBackground(),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Welcome to the Community", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white))
                        .animate().fadeIn().slideX(),
                    const SizedBox(height: 8),
                    Text("Please provide your details accurately.", style: GoogleFonts.inter(color: Colors.white70))
                        .animate().fadeIn(delay: 100.ms).slideX(),
                    const SizedBox(height: 32),
            
                    _buildSectionTitle("Personal Info"),
                    _buildTextField(_nameController, "Full Name", Icons.person_outline).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildDropdown("Gender", Icons.wc, _genders, _selectedGender, (v) => setState(() => _selectedGender = v))),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField(_ageController, "Age", Icons.cake_outlined, isNumber: true)),
                      ],
                    ).animate().fadeIn(delay: 300.ms),

                    const SizedBox(height: 32),
                    _buildSectionTitle("Medical Info"),
                    Row(
                      children: [
                         Expanded(child: _buildDropdown("Blood Type", Icons.bloodtype, _bloodGroups, _selectedBloodGroup, (v) => setState(() => _selectedBloodGroup = v))),
                      ],
                    ).animate().fadeIn(delay: 400.ms),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(_weightController, "Weight (kg)", Icons.monitor_weight_outlined, isNumber: true)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField(_heightController, "Height (cm)", Icons.height, isNumber: true)),
                      ],
                    ).animate().fadeIn(delay: 500.ms),
                    const SizedBox(height: 16),
                    _buildTextField(_medsController, "Medications (if any)", Icons.medication_outlined, isRequired: false).animate().fadeIn(delay: 600.ms),

                    const SizedBox(height: 32),
                    _buildSectionTitle("Location & Contact"),
                    
                    // Location Picker
                    InkWell(
                      onTap: _showLocationPicker,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _latitude != null ? AppTheme.primaryRed.withOpacity(0.5) : Colors.white10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.location_on, color: _latitude != null ? AppTheme.primaryRed : Colors.grey),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Your Location", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  Text(_locationStatus, style: TextStyle(color: _latitude != null ? Colors.white : Colors.white54, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 700.ms),
                    
                    const SizedBox(height: 16),
                    _buildTextField(_phoneController, "Mobile", Icons.phone_iphone, isPhone: true).animate().fadeIn(delay: 800.ms),
                    const SizedBox(height: 16),
                    _buildDropdown("Availability", Icons.access_time, _availabilityOptions, _availability, (v) => setState(() => _availability = v)).animate().fadeIn(delay: 900.ms),

                    const SizedBox(height: 48),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Save & Continue"),
                      ),
                    ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.3)
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.bold, fontSize: 16)),
          const Divider(color: Colors.white24, height: 24),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNumber = false, bool isPhone = false, bool isRequired = true}) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: isNumber ? TextInputType.number : (isPhone ? TextInputType.phone : TextInputType.text),
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      validator: isRequired ? (v) => v!.isEmpty ? "Required" : null : null,
    );
  }

  Widget _buildDropdown(String label, IconData icon, List<String> items, String? value, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: const Color(0xFF1E1E1E),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      items: items.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
      onChanged: onChanged,
    );
  }
}
