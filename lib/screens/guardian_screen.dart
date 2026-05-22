import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../widgets/guardian_card.dart';
import '../widgets/custom_button.dart';
import 'permissions_screen.dart';

class GuardianScreen extends StatefulWidget {
  const GuardianScreen({Key? key}) : super(key: key);

  @override
  State<GuardianScreen> createState() => _GuardianScreenState();
}

class _GuardianScreenState extends State<GuardianScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedRelationship = 'Spouse';
  final List<String> _relationships = ['Spouse', 'Father', 'Mother', 'Sibling', 'Friend', 'Child', 'Other'];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _showAddContactSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Emergency Contact',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Guardian Name',
                  hintText: 'e.g. John Doe',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'e.g. +1 555-0199',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedRelationship,
                decoration: const InputDecoration(labelText: 'Relationship'),
                items: _relationships.map((r) {
                  return DropdownMenuItem(value: r, child: Text(r));
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedRelationship = val!;
                  });
                },
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Add Contact',
                onPressed: () {
                  if (_nameController.text.isNotEmpty && _phoneController.text.isNotEmpty) {
                    final state = Provider.of<AppState>(context, listen: false);
                    state.addGuardian(
                      _nameController.text,
                      _phoneController.text,
                      _selectedRelationship,
                    );
                    _nameController.clear();
                    _phoneController.clear();
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Guardian added successfully')),
                    );
                  }
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = Provider.of<AppState>(context);

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Link Guardians',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'These contacts will receive immediate location-based alerts when an emergency is detected.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  
                  // Add guardian button
                  OutlinedButton(
                    onPressed: _showAddContactSheet,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.secondary,
                      side: BorderSide(color: theme.colorScheme.secondary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.add_circle_outline_rounded, size: 20),
                        SizedBox(width: 8),
                        Text('Add Guardian from Contacts', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Guardian List
            Expanded(
              child: state.guardians.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_alt_outlined, size: 64, color: theme.colorScheme.primary.withOpacity(0.2)),
                          const SizedBox(height: 16),
                          Text(
                            'No guardians linked yet',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.primary.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text('Add at least one guardian to continue', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: state.guardians.length,
                      itemBuilder: (context, index) {
                        final g = state.guardians[index];
                        return GuardianCard(
                          guardian: g,
                          onRemove: () {
                            state.removeGuardian(g.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Guardian removed')),
                            );
                          },
                        );
                      },
                    ),
            ),

            // Bottom Action
            Padding(
              padding: const EdgeInsets.all(24),
              child: CustomButton(
                text: 'Continue',
                onPressed: () {
                  if (state.guardians.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please add at least one guardian before continuing.'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return;
                  }
                  // Navigate to Permissions Screen
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => const PermissionsScreen(),
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
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
