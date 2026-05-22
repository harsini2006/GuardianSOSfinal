import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/app_state.dart';
import '../models/service.dart';
import '../widgets/service_card.dart';

class NearbyServicesScreen extends StatefulWidget {
  const NearbyServicesScreen({Key? key}) : super(key: key);

  @override
  State<NearbyServicesScreen> createState() => _NearbyServicesScreenState();
}

class _NearbyServicesScreenState extends State<NearbyServicesScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildFilterChip(BuildContext context, {required String label, required ServiceCategory? category}) {
    final state = Provider.of<AppState>(context);
    final theme = Theme.of(context);
    final isSelected = state.activeFilterCategory == category;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
            color: isSelected ? Colors.white : (theme.brightness == Brightness.dark ? Colors.white70 : Colors.black87),
          ),
        ),
        selected: isSelected,
        selectedColor: theme.colorScheme.secondary,
        checkmarkColor: Colors.white,
        backgroundColor: theme.brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
        onSelected: (selected) {
          state.filterServices(selected ? category : null);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = Provider.of<AppState>(context);

    // Apply text search on top of category filters
    final displayServices = state.filteredServices.where((s) {
      if (_searchQuery.isEmpty) return true;
      return s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.address.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Nearby Assistance',
          style: theme.textTheme.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : theme.colorScheme.primary),
          onPressed: () {
            // Clear filter and pop
            state.filterServices(null);
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Input Box
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: 'Search hospitals, towing, fuel, food...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              ),
            ),

            // Horizontal Filter Chips list
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                children: [
                  _buildFilterChip(context, label: 'All Services', category: null),
                  _buildFilterChip(context, label: 'Hospitals', category: ServiceCategory.hospital),
                  _buildFilterChip(context, label: 'Ambulances', category: ServiceCategory.ambulance),
                  _buildFilterChip(context, label: 'Police', category: ServiceCategory.police),
                  _buildFilterChip(context, label: 'Towing', category: ServiceCategory.towing),
                  _buildFilterChip(context, label: 'Medical Shops', category: ServiceCategory.medical),
                  _buildFilterChip(context, label: 'Hotels', category: ServiceCategory.hotel),
                  _buildFilterChip(context, label: 'Restaurants', category: ServiceCategory.restaurant),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Services Count text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Text(
                'Found ${displayServices.length} safety services nearby',
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
            const SizedBox(height: 8),

            // List of matching service cards
            Expanded(
              child: displayServices.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded, size: 56, color: theme.colorScheme.primary.withOpacity(0.2)),
                          const SizedBox(height: 12),
                          const Text('No matching services found', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          const Text('Try changing filters or search query', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: displayServices.length,
                      itemBuilder: (context, index) {
                        final service = displayServices[index];
                        return ServiceCard(
                          service: service,
                          onCall: () {
                            final cleaned = service.phone.replaceAll(RegExp(r'[\s\-()]+'), '');
                            launchUrl(Uri.parse('tel:$cleaned'));
                          },
                          onNavigate: () {
                            // Open Google Maps to the real service location
                            final sLat = state.userLat + service.mockLatOffset;
                            final sLng = state.userLng + service.mockLngOffset;
                            launchUrl(
                              Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$sLat,$sLng'),
                              mode: LaunchMode.externalApplication,
                            );
                          },
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
