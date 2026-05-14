import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Brand tokens (same as HomeScreen)
// ─────────────────────────────────────────────────────────────────────────────
class SafeHerColors {
  static const primary      = Color(0xFF6A1B9A);
  static const primaryLight = Color(0xFF9C4DCC);
  static const primaryDark  = Color(0xFF38006B);
  static const accent       = Color(0xFFE040FB);
  static const sosPink      = Color(0xFFEC407A);
  static const softPurple   = Color(0xFFF3E5F5);
  static const textDark     = Color(0xFF212121);
  static const textMuted    = Color(0xFF757575);
  static const openGreen    = Color(0xFF43A047);
  static const emergencyRed = Color(0xFFE53935);
}

// ─────────────────────────────────────────────────────────────────────────────
//  Trusted Contact model
// ─────────────────────────────────────────────────────────────────────────────
class TrustedContact {
  final String name;
  final Color color;
  const TrustedContact({required this.name, required this.color});
}

// ─────────────────────────────────────────────────────────────────────────────
//  TrackingProvider  –  centralises all mutable state for this screen
// ─────────────────────────────────────────────────────────────────────────────
class TrackingProvider extends ChangeNotifier {
  // ── location ──────────────────────────────────────────────────────────────
  LatLng? currentPosition;
  StreamSubscription<Position>? _positionSub;

  // ── destination (hard-coded demo; swap for real destination) ──────────────
  final LatLng destination = const LatLng(37.7849, -122.4094);

  // ── route polyline points (straight-line demo) ────────────────────────────
  List<LatLng> routePoints = [];

  // ── ETA / progress ────────────────────────────────────────────────────────
  double progressValue = 0.0;   // 0.0 → 1.0
  int etaMinutes = 12;          // display value

  // ── contacts ──────────────────────────────────────────────────────────────
  final List<TrustedContact> contacts = [
    const TrustedContact(name: 'Mom',    color: Color(0xFF7B1FA2)),
    const TrustedContact(name: 'Sara',   color: Color(0xFFAD1457)),
    const TrustedContact(name: 'Nadia',  color: Color(0xFF1565C0)),
  ];

  // ── tracking active flag ──────────────────────────────────────────────────
  bool isTracking = false;
  bool isInitialized = false;

  // ── initialization future ────────────────────────────────────────────────
  Future<void>? initFuture;

  // ── initial total distance (metres) set on first fix ─────────────────────
  double? _totalDistance;

  Future<void> initialize() async {
    if (isInitialized) return;

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Handle service disabled - for now we'll just throw to be caught by FutureBuilder
        throw Exception('Location services are disabled.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied.');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      }

      // Get initial position before marking as initialized
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      currentPosition = LatLng(pos.latitude, pos.longitude);
      
      isInitialized = true;
      notifyListeners();
      
      // Automatically start the tracking stream after successful init
      startTracking();
    } catch (e) {
      debugPrint('Error initializing location: $e');
      rethrow;
    }
  }

  void startTracking() {
    if (_positionSub != null) return;

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // metres between updates
      ),
    ).listen((pos) {
      currentPosition = LatLng(pos.latitude, pos.longitude);

      // Build a simple two-point route for the demo
      routePoints = [currentPosition!, destination];

      // Calculate progress
      final distLeft = _haversineMetres(currentPosition!, destination);
      _totalDistance ??= distLeft; // capture on first fix

      if (_totalDistance != null && _totalDistance! > 0) {
        progressValue = 1.0 - (distLeft / _totalDistance!).clamp(0.0, 1.0);
        // Rough ETA: assume 5 km/h walking speed
        etaMinutes = (distLeft / (5000 / 60)).round().clamp(0, 999);
      }

      notifyListeners();
    });
  }

  void stopTracking() {
    _positionSub?.cancel();
    isTracking = false;
    notifyListeners();
  }

  void addContact(TrustedContact c) {
    contacts.add(c);
    notifyListeners();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  // Haversine distance in metres between two LatLngs
  static double _haversineMetres(LatLng a, LatLng b) {
    const r = 6371000.0;
    final dLat = _deg2rad(b.latitude  - a.latitude);
    final dLon = _deg2rad(b.longitude - a.longitude);
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(a.latitude)) *
            math.cos(_deg2rad(b.latitude)) *
            math.sin(dLon / 2) * math.sin(dLon / 2);
    return 2 * r * math.asin(math.sqrt(h));
  }

  static double _deg2rad(double deg) => deg * math.pi / 180;
}

// ─────────────────────────────────────────────────────────────────────────────
//  Custom dark-purple Google Maps JSON style
// ─────────────────────────────────────────────────────────────────────────────
const String _mapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#1a0030"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#9C4DCC"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#1a0030"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"visibility":"off"}]},
  {"featureType":"administrative.country","elementType":"labels.text.fill","stylers":[{"color":"#9e9e9e"}]},
  {"featureType":"administrative.land_parcel","stylers":[{"visibility":"off"}]},
  {"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#CE93D8"}]},
  {"featureType":"poi","elementType":"labels.text","stylers":[{"visibility":"off"}]},
  {"featureType":"poi","elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#263c3f"}]},
  {"featureType":"poi.park","elementType":"labels.text.fill","stylers":[{"color":"#6b9a76"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#38006B"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#6A1B9A"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#CE93D8"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#6A1B9A"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#9C4DCC"}]},
  {"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#f3d19c"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0d0021"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#515c6d"}]},
  {"featureType":"water","elementType":"labels.text.stroke","stylers":[{"color":"#17263c"}]}
]
''';

// ─────────────────────────────────────────────────────────────────────────────
//  TrackingScreen  –  entry point
// ─────────────────────────────────────────────────────────────────────────────
class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  late TrackingProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = TrackingProvider();
    // Start initialization asynchronously
    _provider.initFuture = _provider.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: const _TrackingScaffold(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _TrackingScaffold  –  holds the nav-index state
// ─────────────────────────────────────────────────────────────────────────────
class _TrackingScaffold extends StatefulWidget {
  const _TrackingScaffold();

  @override
  State<_TrackingScaffold> createState() => _TrackingScaffoldState();
}

class _TrackingScaffoldState extends State<_TrackingScaffold> {
  int _navIndex = 1; // 'Track' tab selected by default

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: _buildAppBar(context),
        body: const _MapBody(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white.withOpacity(0.95),
      elevation: 0,
      leading: Navigator.canPop(context) 
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: SafeHerColors.primary, size: 20),
              onPressed: () => Navigator.maybePop(context),
            )
          : null,
      title: const Text(
        'SafeHer Tracking',
        style: TextStyle(
          color: SafeHerColors.primaryDark,
          fontWeight: FontWeight.w800,
          fontSize: 18,
          letterSpacing: -0.3,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_rounded,
              color: SafeHerColors.primary, size: 22),
          onPressed: () {},
        ),
      ],
    );
  }

}

// ─────────────────────────────────────────────────────────────────────────────
//  _MapBody  –  full-screen map + overlay widgets + bottom sheet
// ─────────────────────────────────────────────────────────────────────────────
class _MapBody extends StatefulWidget {
  const _MapBody();

  @override
  State<_MapBody> createState() => _MapBodyState();
}

class _MapBodyState extends State<_MapBody> with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  // Demo fallback position (San Francisco)
  static const LatLng _demo = LatLng(37.7749, -122.4194);

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _zoomIn()  => _mapController?.animateCamera(CameraUpdate.zoomIn());
  void _zoomOut() => _mapController?.animateCamera(CameraUpdate.zoomOut());

  void _onMapCreated(GoogleMapController ctrl) {
    _mapController = ctrl;
    ctrl.setMapStyle(_mapStyle);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TrackingProvider>();

    return FutureBuilder(
      future: provider.initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        final center = provider.currentPosition ?? _demo;

        // ── markers ──────────────────────────────────────────────────────────────
        final markers = <Marker>{
          Marker(
            markerId: const MarkerId('user'),
            position: center,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
            infoWindow: const InfoWindow(title: 'You are here'),
          ),
          Marker(
            markerId: const MarkerId('destination'),
            position: provider.destination,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
            infoWindow: const InfoWindow(title: 'Destination'),
          ),
        };

        // ── dashed polyline (simulated via segment list) ──────────────────────────
        final polylines = provider.routePoints.length >= 2
            ? <Polyline>{
                Polyline(
                  polylineId: const PolylineId('route'),
                  points: provider.routePoints,
                  color: SafeHerColors.accent,
                  width: 4,
                  patterns: [PatternItem.dash(20), PatternItem.gap(10)],
                ),
              }
            : <Polyline>{};

        return Stack(
          children: [
            // ── Full-screen map ───────────────────────────────────────────────
            GoogleMap(
              onMapCreated: _onMapCreated,
              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                Factory<OneSequenceGestureRecognizer>(
                  () => EagerGestureRecognizer(),
                ),
              },
              initialCameraPosition: CameraPosition(target: center, zoom: 15),
              markers: markers,
              polylines: polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: false,
              mapToolbarEnabled: false,
            ),

            // ── "Tracking Active" pill ────────────────────────────────────────
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 64),
                  child: _TrackingActivePill(pulseAnim: _pulseAnim),
                ),
              ),
            ),

            // ── Zoom buttons ──────────────────────────────────────────────────
            Positioned(
              right: 16,
              bottom: 280,
              child: _ZoomControls(onZoomIn: _zoomIn, onZoomOut: _zoomOut),
            ),

            // ── Draggable bottom sheet ────────────────────────────────────────
            const _BottomInfoSheet(),
          ],
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Container(
      color: SafeHerColors.softPurple,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: SafeHerColors.primary,
              strokeWidth: 3,
            ),
            const SizedBox(height: 24),
            Text(
              'Initializing Secure Tracking...',
              style: TextStyle(
                color: SafeHerColors.primaryDark.withOpacity(0.8),
                fontWeight: FontWeight.w700,
                fontSize: 16,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Locating your position for safety',
              style: TextStyle(
                color: SafeHerColors.textMuted,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      color: SafeHerColors.softPurple,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: SafeHerColors.emergencyRed, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Initialization Failed',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: SafeHerColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: SafeHerColors.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final provider = context.read<TrackingProvider>();
                setState(() {
                  provider.initFuture = provider.initialize();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: SafeHerColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  "Tracking Active" status pill
// ─────────────────────────────────────────────────────────────────────────────
class _TrackingActivePill extends StatelessWidget {
  final Animation<double> pulseAnim;
  const _TrackingActivePill({required this.pulseAnim});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseAnim,
      builder: (_, child) => Transform.scale(scale: pulseAnim.value, child: child),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: SafeHerColors.primaryDark.withOpacity(0.92),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: SafeHerColors.accent.withOpacity(0.6), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: SafeHerColors.primary.withOpacity(0.5),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 9, height: 9,
              decoration: const BoxDecoration(
                color: SafeHerColors.openGreen,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Tracking Active',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Zoom controls (floating right side)
// ─────────────────────────────────────────────────────────────────────────────
class _ZoomControls extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  const _ZoomControls({required this.onZoomIn, required this.onZoomOut});

  Widget _btn(IconData icon, VoidCallback cb) {
    return GestureDetector(
      onTap: cb,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: SafeHerColors.primary.withOpacity(0.2),
              blurRadius: 8, offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: SafeHerColors.primary, size: 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _btn(Icons.add, onZoomIn),
        const SizedBox(height: 8),
        _btn(Icons.remove, onZoomOut),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Persistent Draggable Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _BottomInfoSheet extends StatelessWidget {
  const _BottomInfoSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.30,
      minChildSize:     0.18,
      maxChildSize:     0.55,
      builder: (ctx, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: SafeHerColors.primaryDark.withOpacity(0.18),
                blurRadius: 30,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            physics: const ClampingScrollPhysics(),
            children: const [
              _SheetHandle(),
              _EtaSection(),
              _DividerLine(),
              _TrustedContactsSection(),
              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Center(
        child: Container(
          width: 40, height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine();

  @override
  Widget build(BuildContext context) =>
      Divider(color: Colors.grey.shade100, height: 1, thickness: 1,
          indent: 20, endIndent: 20);
}

// ─────────────────────────────────────────────────────────────────────────────
//  ETA + progress bar section
// ─────────────────────────────────────────────────────────────────────────────
class _EtaSection extends StatelessWidget {
  const _EtaSection();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TrackingProvider>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row: icon + text + badge
          Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [SafeHerColors.primaryLight, SafeHerColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.navigation_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Estimated Arrival',
                      style: TextStyle(
                        fontSize: 12,
                        color: SafeHerColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${provider.etaMinutes} mins remaining',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: SafeHerColors.textDark,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
              // Progress percentage badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: SafeHerColors.softPurple,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(provider.progressValue * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 12,
                    color: SafeHerColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: provider.progressValue),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              builder: (_, val, __) => LinearProgressIndicator(
                value: val,
                minHeight: 8,
                backgroundColor: SafeHerColors.softPurple,
                valueColor: const AlwaysStoppedAnimation<Color>(
                    SafeHerColors.primary),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Start → Destination label row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                provider.currentPosition == null
                    ? 'Locating…'
                    : '${provider.currentPosition!.latitude.toStringAsFixed(4)}, '
                      '${provider.currentPosition!.longitude.toStringAsFixed(4)}',
                style: const TextStyle(
                    fontSize: 11, color: SafeHerColors.textMuted),
              ),
              const Text('Destination',
                  style: TextStyle(
                      fontSize: 11,
                      color: SafeHerColors.primary,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Trusted Contacts section
// ─────────────────────────────────────────────────────────────────────────────
class _TrustedContactsSection extends StatelessWidget {
  const _TrustedContactsSection();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TrackingProvider>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Trusted Contacts Watching',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: SafeHerColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${provider.contacts.length} contacts tracking your journey',
                    style: const TextStyle(
                        fontSize: 11, color: SafeHerColors.textMuted),
                  ),
                ],
              ),
              // "All safe" green badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: SafeHerColors.openGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '✓ All safe',
                  style: TextStyle(
                    fontSize: 11,
                    color: SafeHerColors.openGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Horizontal avatar list
          SizedBox(
            height: 78,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // Add button
                _AddContactAvatar(
                  onTap: () => _showAddContactDialog(context, provider),
                ),
                const SizedBox(width: 12),
                // Contact avatars
                ...provider.contacts.map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _ContactAvatar(contact: c),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddContactDialog(BuildContext context, TrackingProvider provider) {
    final ctrl = TextEditingController();
    final colors = [
      const Color(0xFF7B1FA2),
      const Color(0xFFAD1457),
      const Color(0xFF1565C0),
      const Color(0xFF2E7D32),
      const Color(0xFFE65100),
    ];
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add Trusted Contact',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            hintText: 'Contact name',
            filled: true,
            fillColor: SafeHerColors.softPurple,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: SafeHerColors.textMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: SafeHerColors.primary),
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                provider.addContact(TrustedContact(
                  name: ctrl.text.trim(),
                  color: colors[provider.contacts.length % colors.length],
                ));
              }
              Navigator.pop(context);
            },
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _AddContactAvatar extends StatelessWidget {
  final VoidCallback onTap;
  const _AddContactAvatar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: SafeHerColors.primary.withOpacity(0.4), width: 2),
              color: SafeHerColors.softPurple,
            ),
            child: const Icon(Icons.add, color: SafeHerColors.primary, size: 24),
          ),
          const SizedBox(height: 6),
          const Text('Add',
              style: TextStyle(
                  fontSize: 11,
                  color: SafeHerColors.textMuted,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ContactAvatar extends StatelessWidget {
  final TrustedContact contact;
  const _ContactAvatar({required this.contact});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: contact.color,
              child: Text(
                contact.name[0].toUpperCase(),
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
            ),
            // Live-watching indicator
            Positioned(
              bottom: 0, right: 0,
              child: Container(
                width: 14, height: 14,
                decoration: BoxDecoration(
                  color: SafeHerColors.openGreen,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 50,
          child: Text(
            contact.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 11,
                color: SafeHerColors.textDark,
                fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}