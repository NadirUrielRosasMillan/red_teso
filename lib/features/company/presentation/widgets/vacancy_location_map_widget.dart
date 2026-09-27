import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:red_teso/core/theme/app_theme.dart';

/// Coordenadas fijas del Campus TESOEM (Los Reyes Acaquilpan / La Paz, Edo. Méx.)
final LatLng kTesoemLatLng = const LatLng(19.3621, -98.9806);

/// Modelo de datos de ubicación real con coordenadas geográficas
class RealLocationData {
  final String title;
  final String zone;
  final String address;
  final LatLng coordinates;
  final double distanceKm;
  final int commuteMinutes;
  final String transportTip;
  final IconData icon;

  const RealLocationData({
    required this.title,
    required this.zone,
    required this.address,
    required this.coordinates,
    required this.distanceKm,
    required this.commuteMinutes,
    required this.transportTip,
    required this.icon,
  });
}

/// Puntos de interés prestablecidos en el Estado de México y CDMX
final List<RealLocationData> kPresetRealLocations = [
  RealLocationData(
    title: 'Los Reyes La Paz / Cerca TESOEM',
    zone: 'La Paz, Estado de México',
    address: 'Carretera Federal México-Puebla Km 17.5, Los Reyes Acaquilpan',
    coordinates: const LatLng(19.3621, -98.9806),
    distanceKm: 0.8,
    commuteMinutes: 5,
    transportTip: 'A 5 mins de TESOEM (Caminando / Combi Local)',
    icon: Icons.directions_walk_rounded,
  ),
  RealLocationData(
    title: 'Chalco Centro / Plaza Paseo Chalco',
    zone: 'Chalco, Estado de México',
    address: 'Av. Cuauhtémoc Centro, Chalco, Edo. Méx.',
    coordinates: const LatLng(19.2625, -98.8970),
    distanceKm: 14.2,
    commuteMinutes: 25,
    transportTip: 'Ruta Directa Combi Chalco-Zaragoza',
    icon: Icons.directions_bus_rounded,
  ),
  RealLocationData(
    title: 'Ixtapaluca / Plaza Sendero',
    zone: 'Ixtapaluca, Estado de México',
    address: 'Carretera Federal México-Cuautla Km 30',
    coordinates: const LatLng(19.3102, -98.8895),
    distanceKm: 11.5,
    commuteMinutes: 20,
    transportTip: 'Ruta México-Cuautla o Autopista',
    icon: Icons.directions_car_rounded,
  ),
  RealLocationData(
    title: 'Metro Santa Marta / Cablebús L2',
    zone: 'Línea A, CDMX / La Paz',
    address: 'Calzada Ignacio Zaragoza & Metro Santa Marta',
    coordinates: const LatLng(19.3601, -98.9950),
    distanceKm: 4.8,
    commuteMinutes: 12,
    transportTip: 'Metro Línea A o Cablebús L2 Directo',
    icon: Icons.subway_rounded,
  ),
  RealLocationData(
    title: 'CDMX Oriente / Zaragoza / Aeropuerto',
    zone: 'Venustiano Carranza, CDMX',
    address: 'Calzada Ignacio Zaragoza & Av. Hangares',
    coordinates: const LatLng(19.4120, -99.0750),
    distanceKm: 15.0,
    commuteMinutes: 30,
    transportTip: 'Metro Línea 1/9 o Transp. Zaragoza',
    icon: Icons.location_city_rounded,
  ),
  RealLocationData(
    title: 'CDMX Centro / Reforma / Polanco',
    zone: 'Zona Corporativa, CDMX',
    address: 'Paseo de la Reforma & Insurgentes Sur',
    coordinates: const LatLng(19.4326, -99.1332),
    distanceKm: 25.0,
    commuteMinutes: 50,
    transportTip: 'Metro Línea A + Línea 1/9',
    icon: Icons.business_rounded,
  ),
  RealLocationData(
    title: 'Trabajo Remoto / Desde Casa',
    zone: '100% Home Office',
    address: 'Modalidad remota flexible',
    coordinates: const LatLng(19.3621, -98.9806),
    distanceKm: 0.0,
    commuteMinutes: 0,
    transportTip: 'Sin desplazamientos requeridos',
    icon: Icons.laptop_chromebook_rounded,
  ),
];

/// Widget del Mapa Interactivo Real (OpenStreetMap)
class VacancyLocationMapWidget extends StatefulWidget {
  final String locationName;
  final double distanceKm;
  final int commuteMinutes;
  final String transportTip;
  final LatLng? locationCoordinates;

  const VacancyLocationMapWidget({
    super.key,
    required this.locationName,
    this.distanceKm = 4.8,
    this.commuteMinutes = 15,
    this.transportTip = 'Combi directa desde TESOEM o Metro Santa Marta',
    this.locationCoordinates,
  });

  @override
  State<VacancyLocationMapWidget> createState() => _VacancyLocationMapWidgetState();
}

class _VacancyLocationMapWidgetState extends State<VacancyLocationMapWidget> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  LatLng _resolveTargetLatLng() {
    if (widget.locationCoordinates != null) {
      return widget.locationCoordinates!;
    }
    final match = kPresetRealLocations.firstWhere(
      (loc) => loc.title.toLowerCase().contains(widget.locationName.toLowerCase()),
      orElse: () => kPresetRealLocations[0],
    );
    return match.coordinates;
  }

  @override
  Widget build(BuildContext context) {
    final targetLatLng = _resolveTargetLatLng();
    final isRemote = widget.locationName.toLowerCase().contains('remoto') || widget.distanceKm == 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado de la Tarjeta
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.map_rounded, color: AppTheme.primaryColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mapa Interactivo y Movilidad',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        isRemote ? 'Modalidad 100% Home Office' : widget.locationName,
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Contenedor del Mapa Real Interactivo OpenStreetMap
          ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            child: SizedBox(
              height: 240,
              width: double.infinity,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: targetLatLng,
                      initialZoom: 12.5,
                      minZoom: 9.0,
                      maxZoom: 18.0,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all,
                      ),
                    ),
                    children: [
                      // Capa de Mapa Real OpenStreetMap
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.red_teso',
                      ),

                      // Línea de Ruta conectora entre TESOEM y la Empresa
                      if (!isRemote)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: [kTesoemLatLng, targetLatLng],
                              color: AppTheme.primaryColor,
                              strokeWidth: 3.5,
                            ),
                          ],
                        ),

                      // Marcadores (Pines 📍)
                      MarkerLayer(
                        markers: [
                          // Pin 1: Campus TESOEM
                          Marker(
                            point: kTesoemLatLng,
                            width: 90,
                            height: 70,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor,
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                  ),
                                  child: Text(
                                    '🎓 TESOEM',
                                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const Icon(Icons.location_on_rounded, color: AppTheme.primaryColor, size: 30),
                              ],
                            ),
                          ),

                          // Pin 2: Empresa / Vacante
                          Marker(
                            point: targetLatLng,
                            width: 100,
                            height: 70,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isRemote ? Colors.purple : Colors.redAccent,
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                  ),
                                  child: Text(
                                    isRemote ? '💻 Remoto' : '📍 Empresa',
                                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Icon(
                                  isRemote ? Icons.home_work_rounded : Icons.business_center_rounded,
                                  color: isRemote ? Colors.purple : Colors.redAccent,
                                  size: 28,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Badge Flotante Superior con Distancia y Tiempo
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.accentColor.withValues(alpha: 0.5)),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.directions_bus_rounded, color: AppTheme.accentColor, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            isRemote
                                ? 'Sin traslado requerido'
                                : '⏱️ ~${widget.commuteMinutes} min (${widget.distanceKm.toStringAsFixed(1)} km desde TESOEM)',
                            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Controles de Zoom (+ / -)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () {
                            _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                            ),
                            child: const Icon(Icons.add_rounded, color: Color(0xFF0F172A), size: 20),
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () {
                            _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                            ),
                            child: const Icon(Icons.remove_rounded, color: Color(0xFF0F172A), size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Barra Inferior con Recomendación de Transporte
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      color: const Color(0xFF0F172A).withValues(alpha: 0.92),
                      child: Row(
                        children: [
                          const Icon(Icons.alt_route_rounded, color: AppTheme.accentColor, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.transportTip,
                              style: GoogleFonts.inter(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Modal Interactivo de Selección de Ubicación Real en el Mapa
class LocationPickerModal extends StatefulWidget {
  final String currentSelection;

  const LocationPickerModal({super.key, required this.currentSelection});

  static Future<RealLocationData?> show(BuildContext context, {String current = ''}) async {
    return await showModalBottomSheet<RealLocationData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LocationPickerModal(currentSelection: current),
    );
  }

  @override
  State<LocationPickerModal> createState() => _LocationPickerModalState();
}

class _LocationPickerModalState extends State<LocationPickerModal> {
  late MapController _pickerMapController;
  late LatLng _selectedLatLng;
  late String _selectedTitle;
  late String _selectedZone;
  late String _selectedAddress;
  late double _distanceKm;
  late int _commuteMinutes;
  late String _transportTip;

  final Distance _distanceCalculator = const Distance();

  @override
  void initState() {
    super.initState();
    _pickerMapController = MapController();

    final match = kPresetRealLocations.firstWhere(
      (loc) => loc.title.toLowerCase().contains(widget.currentSelection.toLowerCase()),
      orElse: () => kPresetRealLocations[0],
    );

    _selectedLatLng = match.coordinates;
    _selectedTitle = match.title;
    _selectedZone = match.zone;
    _selectedAddress = match.address;
    _distanceKm = match.distanceKm;
    _commuteMinutes = match.commuteMinutes;
    _transportTip = match.transportTip;
  }

  void _onMapTapped(LatLng point) {
    final dist = _distanceCalculator.as(LengthUnit.Kilometer, kTesoemLatLng, point);
    final minutes = (dist * 2.2).round().clamp(5, 90);

    setState(() {
      _selectedLatLng = point;
      _selectedTitle = 'Punto Seleccionado en Mapa';
      _selectedZone = 'Estado de México / CDMX';
      _selectedAddress = 'Lat: ${point.latitude.toStringAsFixed(4)}, Lng: ${point.longitude.toStringAsFixed(4)}';
      _distanceKm = double.parse(dist.toStringAsFixed(1));
      _commuteMinutes = minutes;
      _transportTip = 'Traslado estimado de ~$minutes mins desde el Campus TESOEM';
    });
  }

  void _selectPreset(RealLocationData preset) {
    setState(() {
      _selectedLatLng = preset.coordinates;
      _selectedTitle = preset.title;
      _selectedZone = preset.zone;
      _selectedAddress = preset.address;
      _distanceKm = preset.distanceKm;
      _commuteMinutes = preset.commuteMinutes;
      _transportTip = preset.transportTip;
    });
    _pickerMapController.move(preset.coordinates, 13.5);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Row(
              children: [
                const Icon(Icons.map_rounded, color: AppTheme.primaryColor, size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seleccionar Ubicación Real en Mapa',
                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                      ),
                      Text(
                        'Toca el mapa para mover el Pin 📍 o elige un punto rápido',
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Mapa Interactivo para Selección con Toque / Arrastre
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _pickerMapController,
                  options: MapOptions(
                    initialCenter: _selectedLatLng,
                    initialZoom: 13.0,
                    minZoom: 8.0,
                    maxZoom: 18.0,
                    onTap: (tapPosition, point) => _onMapTapped(point),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.red_teso',
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: [kTesoemLatLng, _selectedLatLng],
                          color: AppTheme.primaryColor,
                          strokeWidth: 3.5,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        // TESOEM
                        Marker(
                          point: kTesoemLatLng,
                          width: 80,
                          height: 60,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(6)),
                                child: Text('🎓 TESOEM', style: GoogleFonts.outfit(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                              ),
                              const Icon(Icons.location_on_rounded, color: AppTheme.primaryColor, size: 28),
                            ],
                          ),
                        ),
                        // Ubicación Seleccionada
                        Marker(
                          point: _selectedLatLng,
                          width: 100,
                          height: 70,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(6)),
                                child: Text('📍 Empresa', style: GoogleFonts.outfit(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                              ),
                              const Icon(Icons.location_on_rounded, color: Colors.redAccent, size: 32),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Lista Horizontal de accesos rápidos a zonas
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: SizedBox(
                    height: 38,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: kPresetRealLocations.length,
                      itemBuilder: (context, index) {
                        final preset = kPresetRealLocations[index];
                        final isSel = preset.title == _selectedTitle;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            avatar: Icon(preset.icon, size: 15, color: isSel ? Colors.white : AppTheme.primaryColor),
                            label: Text(preset.title, style: GoogleFonts.inter(fontSize: 11.5, color: isSel ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.bold)),
                            selected: isSel,
                            selectedColor: AppTheme.primaryColor,
                            backgroundColor: Colors.white,
                            onSelected: (_) => _selectPreset(preset),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Indicador Flotante de Coordenadas y Distancia
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.place_rounded, color: AppTheme.accentColor, size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _selectedTitle,
                                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                              ),
                              Text(
                                '⏱️ ~$_commuteMinutes min ($_distanceKm km desde TESOEM)',
                                style: GoogleFonts.inter(color: AppTheme.accentColor, fontSize: 11.5, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Botón Confirmar Selección
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    RealLocationData(
                      title: _selectedTitle,
                      zone: _selectedZone,
                      address: _selectedAddress,
                      coordinates: _selectedLatLng,
                      distanceKm: _distanceKm,
                      commuteMinutes: _commuteMinutes,
                      transportTip: _transportTip,
                      icon: Icons.place_rounded,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  'CONFIRMAR UBICACIÓN SELECCIONADA 📍',
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
