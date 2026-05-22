import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/user_profile.dart';
import '../widgets/custom_button.dart';
import 'guardian_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({Key? key}) : super(key: key);

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _medicalController = TextEditingController();
  
  String _selectedBlood = 'A+';
  String _selectedVehicle = 'Two Wheeler';
  bool _photoUploaded = false;

  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];
  final List<String> _vehicleTypes = ['Two Wheeler', 'Four Wheeler', 'Heavy Vehicle', 'None (Pedestrian)'];

  @override
  void dispose() {
    _nameController.dispose();
    _medicalController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (_formKey.currentState!.validate()) {
      final state = Provider.of<AppState>(context, listen: false);
      state.saveProfile(
        UserProfile(
          name: _nameController.text,
          phone: state.userPhone,
          bloodGroup: _selectedBlood,
          vehicleType: _selectedVehicle,
          medicalNotes: _medicalController.text,
          photoPath: _photoUploaded ? 'assets/avatar.png' : '',
        ),
      );

      // Navigate to Add Guardians Screen
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const GuardianScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(1, 0), end: Offset.zero).chain(CurveTween(curve: Curves.ease)),
              ),
              child: child,
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : theme.colorScheme.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profile Setup',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Fill in your medical details. This info will be shared with emergency response teams in critical situations.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),

                // Profile Image Upload Indicator
                Center(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _photoUploaded = !_photoUploaded;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_photoUploaded ? 'Photo uploaded successfully' : 'Photo removed'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                          child: _photoUploaded
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(50),
                                  child: Container(
                                    color: theme.colorScheme.secondary,
                                    child: const Center(
                                      child: Icon(Icons.person, size: 50, color: Colors.white),
                                    ),
                                  ),
                                )
                              : Icon(Icons.add_a_photo_rounded, size: 32, color: theme.colorScheme.secondary),
                        ),
                        if (_photoUploaded)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                              child: const Icon(Icons.check, size: 16, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Name Input
                Text(
                  'FULL NAME',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.0),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Anbu Selvan',
                    contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Row of drop-downs
                Row(
                  children: [
                    // Blood group
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BLOOD GROUP',
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.0),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedBlood,
                            items: _bloodGroups.map((group) {
                              return DropdownMenuItem(value: group, child: Text(group, style: const TextStyle(fontWeight: FontWeight.bold)));
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedBlood = val!;
                              });
                            },
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Vehicle Type
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'VEHICLE TYPE',
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.0),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedVehicle,
                            items: _vehicleTypes.map((vehicle) {
                              return DropdownMenuItem(
                                value: vehicle,
                                child: Text(
                                  vehicle.split(' ').first,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedVehicle = val!;
                              });
                            },
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Medical Notes Input
                Text(
                  'MEDICAL NOTES / CONDITIONS (OPTIONAL)',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.0),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _medicalController,
                  maxLines: 3,
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                  decoration: const InputDecoration(
                    hintText: 'Allergies, chronic conditions, regular prescriptions, etc.',
                    contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                ),
                const SizedBox(height: 40),

                // Save button
                CustomButton(
                  text: 'Save & Continue',
                  onPressed: _onSave,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
