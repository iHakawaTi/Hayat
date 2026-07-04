import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';

import '../../../core/theme/app_theme.dart';
import '../../../core/presentation/widgets/premium_background.dart';
import '../../auth/data/auth_repository.dart';
import '../data/donor_repository.dart';

// Helper to force refresh - Removed, using ref.refresh instead

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  
  void _startEdit(String label, String dbField, String currentValue, {bool isNumber = false}) {
    // Don't show "N/A" in the edit box, show empty
    final initialText = currentValue == 'N/A' || currentValue == '-' ? '' : currentValue;
    final controller = TextEditingController(text: initialText);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true, // Show above the nav bar
      backgroundColor: Colors.transparent,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            top: 24, left: 24, right: 24
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E).withOpacity(0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Edit $label", style: GoogleFonts.outfit(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                keyboardType: isNumber ? TextInputType.number : TextInputType.text,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.check_circle, color: AppTheme.primaryRed, size: 32),
                    onPressed: () async {
                      try {
                        // Save Logic
                        dynamic val;
                        if (isNumber) {
                           if (controller.text.isEmpty) {
                             val = null;
                           } else {
                             val = num.tryParse(controller.text);
                             if (val == null) {
                               ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text("Invalid Number")));
                               return;
                             }
                           }
                        } else {
                          val = controller.text;
                        }

                        final user = ref.read(authRepositoryProvider).currentUser;
                        if (user != null) {
                          Navigator.pop(ctx);
                          // Show loading indicator or optimistic update? For now just await.
                          await ref.read(donorRepositoryProvider).updateDonorField(user.id, dbField, val);
                          
                          // Invalidate the specific family provider to trigger refetch
                          ref.invalidate(donorProfileProvider(user.id));
                          
                          if (mounted) {
                             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Saved!"), backgroundColor: Colors.green));
                          }
                        }
                      } catch (e) {
                         Navigator.pop(ctx);
                         if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Save Failed: $e"), backgroundColor: Colors.red));
                         }
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text("Tap checkmark to save", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ref.watch(profileRefreshProvider); // Removed
    final user = ref.read(authRepositoryProvider).currentUser;
    final profileFuture = ref.watch(donorProfileProvider(user?.id ?? ''));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("My Profile", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
           const PremiumBackground(),
          SafeArea(
            child: profileFuture.when(
              data: (donor) {
                if (donor == null) return const Center(child: Text("No Profile Found", style: TextStyle(color: Colors.white)));
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // Header Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [AppTheme.primaryRed, AppTheme.darkRed]),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: AppTheme.primaryRed.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.white,
                              child: Text(donor.bloodGroup, style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primaryRed)),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(donor.fullName, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                                  Text(donor.donorCode, style: GoogleFonts.inter(color: Colors.white70)),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)),
                                    child: Text("Tap fields to edit", style: GoogleFonts.inter(fontSize: 12, color: Colors.white)),
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      ).animate().fadeIn().slideY(),
                      const SizedBox(height: 32),
                      
                      _buildSection("Personal Details"),
                      _buildInfoRow(Icons.cake, "Age", "${donor.age ?? 'N/A'}", "age", isNumber: true),
                      _buildInfoRow(Icons.location_city, "City", donor.city, "city"),
                      
                      const SizedBox(height: 24),
                      _buildSection("Physical Metrics"),
                      Row(
                        children: [
                          Expanded(child: _buildInfoCard(Icons.monitor_weight, "Weight", "${donor.weightKg ?? '-'} kg", "weight_kg", isNumber: true)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildInfoCard(Icons.height, "Height", "${donor.heightCm ?? '-'} cm", "height_cm", isNumber: true)),
                        ],
                      ),

                      const SizedBox(height: 24),
                      _buildSection("Medical & Contact"),
                      _buildInfoRow(Icons.medication, "Medications", donor.medications ?? 'None', "medications"),
                      _buildInfoRow(Icons.phone, "Mobile", donor.mobile, "mobile"),
                      _buildInfoRow(Icons.access_time, "Availability", donor.availability ?? 'Anytime', "availability"),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text("Error: $e", style: const TextStyle(color: Colors.red))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, String dbField, {bool isNumber = false}) {
    return InkWell(
      onTap: () => _startEdit(label, dbField, value, isNumber: isNumber),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey, size: 20),
            const SizedBox(width: 16),
            Text(label, style: const TextStyle(color: Colors.grey)),
            const Spacer(),
            Expanded(
               flex: 2,
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.end,
                 children: [
                   Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600), textAlign: TextAlign.right, overflow: TextOverflow.ellipsis),
                   const SizedBox(width: 8),
                   Icon(Icons.edit, size: 14, color: AppTheme.primaryRed.withOpacity(0.5)),
                 ],
               ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value, String dbField, {bool isNumber = false}) {
    return InkWell(
      onTap: () => _startEdit(label, dbField, value.replaceAll(" kg", "").replaceAll(" cm", ""), isNumber: isNumber),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryRed),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
