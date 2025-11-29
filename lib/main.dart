import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'catatan_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const MapScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final List<CatatanModel> _savedNotes = [];
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _loadSavedMarkers();
  }

  Future<void> _loadSavedMarkers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> raw = prefs.getStringList("markers") ?? [];

    setState(() {
      _savedNotes.clear();
      _savedNotes.addAll(raw.map((e) => CatatanModel.fromJson(e)).toList());
    });
  }

  Future<void> _savedMarkers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> raw = _savedNotes.map((e) => e.toJson()).toList();
    prefs.setStringList("markers", raw);
  }

  Future<void> _findMyLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    Position position = await Geolocator.getCurrentPosition();

    _mapController.move(
      latlong.LatLng(position.latitude, position.longitude),
      15.0,
    );
  }

  void _handleLongPress(TapPosition _, latlong.LatLng point) async {
    String? type = await _selectTypeDialog();
    if (type == null) return;

    List<Placemark> placemarks = await placemarkFromCoordinates(
      point.latitude,
      point.longitude,
    );
    String address = placemarks.first.street ?? "Alamat tidak dikenal";

    setState(() {
      _savedNotes.add(
        CatatanModel(
          position: point,
          note: "Info Lokasi",
          address: address,
          type: type,
        ),
      );
    });

    _savedMarkers();
  }

  Future<String?> _selectTypeDialog() async {
    return showDialog<String>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text("Pilih lokasi"),
          children: [
            SimpleDialogOption(
              child: Row(
                children: [
                  Icon(Icons.home_outlined, color: Colors.black87),
                  SizedBox(width: 4),
                  Text("Rumah"),
                ],
              ),
              onPressed: () => Navigator.pop(context, "rumah"),
            ),
            SimpleDialogOption(
              child: Row(
                children: [
                  Icon(Icons.store_outlined, color: Colors.black87),
                  SizedBox(width: 4),
                  Text("Toko"),
                ],
              ),
              onPressed: () => Navigator.pop(context, "toko"),
            ),
            SimpleDialogOption(
              child: Row(
                children: [
                  Icon(Icons.home_work_outlined, color: Colors.black87),
                  SizedBox(width: 4),
                  Text("Kantor"),
                ],
              ),
              onPressed: () => Navigator.pop(context, "kantor"),
            ),
            SimpleDialogOption(
              child: Row(
                children: [
                  Icon(Icons.school_outlined, color: Colors.black87),
                  SizedBox(width: 4),
                  Text("Kampus"),
                ],
              ),
              onPressed: () => Navigator.pop(context, "kampus"),
            ),
          ],
        );
      },
    );
  }

  Icon _buildMarkerIcon(String type) {
    switch (type) {
      case "rumah":
        return Icon(Icons.home, color: Colors.red, size: 35);
      case "toko":
        return Icon(Icons.store, color: Colors.yellow, size: 35);
      case "kantor":
        return Icon(Icons.home_work, color: Colors.green, size: 35);
      case "kampus":
        return Icon(Icons.home_work, color: Colors.blue[900], size: 35);
      default:
        return Icon(Icons.location_on, color: Colors.blue, size: 35);
    }
  }

  void _deletemarker(CatatanModel model) {
    setState(() {
      _savedNotes.remove(model);
    });
    _savedMarkers();
  }

  void _showMarkerDetail(CatatanModel model) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(model.note, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Alamat: ${model.address}"),
            SizedBox(height: 6),
            Text("Jenis Lokasi: ${model.type}"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _deletemarker(model);
              Navigator.pop(context);
            },
            child: Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Tutup"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Geo-Catatan")),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: const latlong.LatLng(-6.2, 106.8),
          initialZoom: 13.0,
          onLongPress: _handleLongPress,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          ),
          MarkerLayer(
            markers: _savedNotes.map((n) {
              return Marker(
                point: n.position,
                child: GestureDetector(
                  onTap: () => _showMarkerDetail(n),
                  child: _buildMarkerIcon(n.type),
                ),
              );
            }).toList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _findMyLocation,
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
