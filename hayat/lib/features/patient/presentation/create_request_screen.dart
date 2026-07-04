import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/presentation/widgets/premium_background.dart';

class CreateRequestScreen extends ConsumerStatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  ConsumerState<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends ConsumerState<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _hospitalController = TextEditingController(); 
  final _unitsController = TextEditingController(text: "1");
  final _reasonController = TextEditingController();
  
  String? _selectedBloodGroup;
  String _urgency = 'High';
  
  bool _isLoading = false;

  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  final List<String> _urgencyLevels = ['Low', 'Medium', 'High', 'Critical'];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedBloodGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all required fields")));
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
       setState(() => _isLoading = false);
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Request Posted! Notifying Donors..."), backgroundColor: Colors.green));
       context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("Request Blood", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.pop(),
        ),
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
                    // Warning Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryRed.withOpacity(0.1),
                        border: Border.all(color: AppTheme.primaryRed.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: AppTheme.primaryRed),
                          const SizedBox(width: 12),
                          Expanded(child: Text("All requests must be verified by a hospital. Misuse will result in a ban.", style: GoogleFonts.inter(color: Colors.white70, fontSize: 13))),
                        ],
                      ),
                    ).animate().fadeIn().slideY(begin: -0.2),
                    
                    const SizedBox(height: 32),
            
                    _buildLabel("Patient Blood Type"),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _bloodGroups.asMap().entries.map((entry) {
                        final index = entry.key;
                        final bg = entry.value;
                        final isSelected = _selectedBloodGroup == bg;
                        return ChoiceChip(
                          label: Text(bg),
                          selected: isSelected,
                          onSelected: (v) => setState(() => _selectedBloodGroup = bg),
                          selectedColor: AppTheme.primaryRed,
                          backgroundColor: Colors.white10,
                          labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: isSelected ? AppTheme.primaryRed : Colors.white10)),
                        ).animate().fadeIn(delay: (50 * index).ms).scale();
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            value: _urgency,
                            dropdownColor: const Color(0xFF1E1E1E),
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: "Urgency", prefixIcon: Icon(Icons.warning)),
                            items: _urgencyLevels.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                            onChanged: (v) => setState(() => _urgency = v!),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _unitsController,
                            style: const TextStyle(color: Colors.white),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: "Units", prefixIcon: Icon(Icons.bloodtype_outlined)),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 200.ms).slideX(),

                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _hospitalController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: "Hospital Name", prefixIcon: Icon(Icons.local_hospital)),
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ).animate().fadeIn(delay: 300.ms).slideX(),

                    const SizedBox(height: 16),
                    TextFormField(
                       controller: _reasonController,
                       style: const TextStyle(color: Colors.white),
                       maxLines: 3,
                       decoration: const InputDecoration(labelText: "Medical Reason (Optional)", prefixIcon: Icon(Icons.note_alt_outlined)),
                    ).animate().fadeIn(delay: 400.ms).slideX(),


                    const SizedBox(height: 48),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _urgency == 'Critical' ? Colors.red : AppTheme.primaryRed,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("POST REQUEST"),
                      ),
                    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.5)
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }
}
