import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:el_asli/core/constants/app_constants.dart';
import 'package:el_asli/core/theme/app_theme.dart';
import 'package:el_asli/data/models/product_model.dart';

class PharmacyScreen extends ConsumerStatefulWidget {
  final ProductModel? product;
  const PharmacyScreen({super.key, this.product});

  @override
  ConsumerState<PharmacyScreen> createState() => _PharmacyScreenState();
}

class _PharmacyScreenState extends ConsumerState<PharmacyScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  List<PharmacyModel> _pharmacies = [];
  PharmacyModel? _selectedPharmacy;
  bool _showOpenOnly = false;
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await _getCurrentLocation();
    _loadPharmacies();
  }


  Future<void> _getCurrentLocation() async {
    try {
      // 1. Service GPS activé ?
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _useFallbackLocation();
        return;
      }

  
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _useFallbackLocation();
          return;
        }
      }

      
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Activez la localisation dans Paramètres pour voir les pharmacies proches'),
              action: SnackBarAction(
                  label: 'Paramètres', onPressed: Geolocator.openAppSettings),
            ),
          );
        }
        _useFallbackLocation();
        return;
      }

      
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (mounted) setState(() => _currentPosition = position);
    } catch (e) {
      debugPrint('Localisation erreur: $e');
      _useFallbackLocation();
    }
  }


  void _useFallbackLocation() {
    if (!mounted) return;
    setState(() => _currentPosition = Position(
          latitude: 36.8190,
          longitude: 10.1657,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        ));
  }

  void _loadPharmacies() {
    final pharmacies = AppConstants.mockPharmacies.map((p) {
      final distance = _currentPosition != null
          ? Geolocator.distanceBetween(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
              (p['lat'] as num).toDouble(),
              (p['lng'] as num).toDouble(),
            )
          : null;

      return PharmacyModel.fromMap({
        ...p,
        'distance': distance,
        'availableProducts':
            widget.product != null ? [widget.product!.name] : <String>[],
      });
    }).toList();

    pharmacies.sort((a, b) =>
        (a.distance ?? double.infinity)
            .compareTo(b.distance ?? double.infinity));

    if (mounted) {
      setState(() {
        _pharmacies = pharmacies;
        _isLoading = false;
      });
    }
  }

  List<PharmacyModel> get _filteredPharmacies =>
      _showOpenOnly ? _pharmacies.where((p) => p.isOpen).toList() : _pharmacies;

  LatLng get _mapCenter => _currentPosition != null
      ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
      : const LatLng(36.8190, 10.1657);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pharmacies proches'),
            if (widget.product != null)
              Text(widget.product!.name,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.primaryGreen)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryGreen,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.map_rounded), text: 'Carte'),
            Tab(icon: Icon(Icons.list_rounded), text: 'Liste'),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('Ouvert', style: TextStyle(fontSize: 11)),
              selected: _showOpenOnly,
              onSelected: (v) => setState(() => _showOpenOnly = v),
              selectedColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
              checkmarkColor: AppTheme.primaryGreen,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.primaryGreen),
                  SizedBox(height: 16),
                  Text('Localisation en cours...',
                      style: TextStyle()),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMapTab(),
                _buildListTab(),
              ],
            ),
    );
  }

  
  Widget _buildMapTab() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _mapCenter,
            initialZoom: 13.0,
            onTap: (_, __) => setState(() => _selectedPharmacy = null),
          ),
          children: [
            // Tuiles OpenStreetMap (sans clé API)
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.elasli.el_asli',
            ),

            // Marqueur position actuelle
            if (_currentPosition != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _mapCenter,
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.accentBlue,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accentBlue
                                .withValues(alpha: 0.4),
                            blurRadius: 8,
                          )
                        ],
                      ),
                      child: const Icon(Icons.my_location_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),

           
            MarkerLayer(
              markers: _filteredPharmacies.map((pharmacy) {
                final isSelected = _selectedPharmacy?.id == pharmacy.id;
                return Marker(
                  point: LatLng(pharmacy.lat, pharmacy.lng),
                  width: isSelected ? 50 : 40,
                  height: isSelected ? 50 : 40,
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _selectedPharmacy = pharmacy),
                    child: Container(
                      decoration: BoxDecoration(
                        color: pharmacy.isOpen
                            ? AppTheme.successGreen
                            : AppTheme.dangerRed,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white,
                            width: isSelected ? 3 : 2),
                        boxShadow: [
                          BoxShadow(
                            color: (pharmacy.isOpen
                                    ? AppTheme.successGreen
                                    : AppTheme.dangerRed)
                                .withValues(alpha: 0.4),
                            blurRadius: isSelected ? 12 : 6,
                          )
                        ],
                      ),
                      child: Icon(
                        Icons.local_pharmacy_rounded,
                        color: Colors.white,
                        size: isSelected ? 26 : 20,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),

        // Attribution OpenStreetMap (obligatoire)
        Positioned(
          bottom: _selectedPharmacy != null ? 165 : 8,
          right: 8,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            color: Colors.white.withValues(alpha: 0.8),
            child: const Text(
              '© OpenStreetMap contributors',
              style: TextStyle(fontSize: 9),
            ),
          ),
        ),

        if (_selectedPharmacy != null)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: _PharmacyDetailCard(
              pharmacy: _selectedPharmacy!,
              onClose: () => setState(() => _selectedPharmacy = null),
            ),
          ),

        // Bouton recentrer
        Positioned(
          top: 16,
          right: 16,
          child: FloatingActionButton.small(
            onPressed: () {
              _mapController.move(_mapCenter, 13.0);
            },
            backgroundColor: Colors.white,
            child: const Icon(Icons.my_location_rounded,
                color: AppTheme.primaryGreen),
          ),
        ),
      ],
    );
  }


  Widget _buildListTab() {
    final list = _filteredPharmacies;

    if (list.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_pharmacy_outlined, size: 60, color: Colors.grey),
            SizedBox(height: 12),
            Text('Aucune pharmacie trouvée',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, i) => _PharmacyListTile(
        pharmacy: list[i],
        onTap: () {
          setState(() => _selectedPharmacy = list[i]);
          _tabController.animateTo(0);
          _mapController.move(
            LatLng(list[i].lat, list[i].lng),
            15.0,
          );
        },
      ),
    );
  }
}

class _PharmacyDetailCard extends StatelessWidget {
  final PharmacyModel pharmacy;
  final VoidCallback onClose;

  const _PharmacyDetailCard(
      {required this.pharmacy, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pharmacy.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                    Text(pharmacy.address,
                        style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey)),
                  ],
                ),
              ),
              IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  padding: EdgeInsets.zero),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Statut
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: pharmacy.isOpen
                      ? AppTheme.successGreen.withValues(alpha: 0.1)
                      : AppTheme.dangerRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  pharmacy.isOpen ? '✅ Ouvert' : '❌ Fermé',
                  style: TextStyle(
                      color: pharmacy.isOpen
                          ? AppTheme.successGreen
                          : AppTheme.dangerRed,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.access_time_rounded,
                  size: 13, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(pharmacy.openHours,
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600)),
              if (pharmacy.distance != null) ...[
                const Spacer(),
                Icon(Icons.near_me_rounded,
                    size: 13, color: AppTheme.accentBlue),
                const SizedBox(width: 4),
                Text(
                  _formatDistance(pharmacy.distance!),
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.accentBlue,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _getDirections(pharmacy),
                  icon: const Icon(Icons.directions_rounded, size: 16),
                  label: const Text('Itinéraire'),
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      textStyle: const TextStyle(
                          fontSize: 13)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _callPharmacy(pharmacy.phone),
                  icon: const Icon(Icons.call_rounded, size: 16),
                  label: const Text('Appeler'),
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      textStyle: const TextStyle(
                          fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _getDirections(PharmacyModel p) async {
    final uri = Uri.parse(
        'https://www.openstreetmap.org/directions?to=${p.lat},${p.lng}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callPharmacy(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  String _formatDistance(double m) =>
      m < 1000 ? '${m.toInt()} m' : '${(m / 1000).toStringAsFixed(1)} km';
}


class _PharmacyListTile extends StatelessWidget {
  final PharmacyModel pharmacy;
  final VoidCallback onTap;

  const _PharmacyListTile(
      {required this.pharmacy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color =
        pharmacy.isOpen ? AppTheme.successGreen : Colors.grey;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ??
              Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            // Icône
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle),
              child: Icon(Icons.local_pharmacy_rounded,
                  color: color, size: 22),
            ),
            const SizedBox(width: 12),
            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pharmacy.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  Text(pharmacy.address,
                      style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded,
                          size: 11, color: color),
                      const SizedBox(width: 4),
                      Text(pharmacy.openHours,
                          style: TextStyle(
                              fontSize: 11,
                              color: color)),
                      if (pharmacy.distance != null) ...[
                        const SizedBox(width: 10),
                        const Icon(Icons.near_me_rounded,
                            size: 11,
                            color: AppTheme.accentBlue),
                        const SizedBox(width: 3),
                        Text(
                          _formatDistance(pharmacy.distance!),
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.accentBlue,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Badges + flèche
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    pharmacy.isOpen ? 'Ouvert' : 'Fermé',
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () async {
                    final uri = Uri.parse('tel:${pharmacy.phone}');
                    if (await canLaunchUrl(uri)) launchUrl(uri);
                  },
                  child: const Icon(Icons.call_rounded,
                      color: AppTheme.primaryGreen, size: 20),
                ),
              ],
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 13, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  String _formatDistance(double m) =>
      m < 1000 ? '${m.toInt()} m' : '${(m / 1000).toStringAsFixed(1)} km';
}
