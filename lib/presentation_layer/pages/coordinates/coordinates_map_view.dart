import 'package:flutter/material.dart';
import '../../../domain_layer/coordinates/point.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logger/presentation_layer/core/coordinate_converter.dart';

class CoordinatesMapView extends StatefulWidget {
  final List<Point> points;
  final String coordinateFormat;

  const CoordinatesMapView({
    super.key,
    required this.points,
    required this.coordinateFormat,
  });

  @override
  State<CoordinatesMapView> createState() => _CoordinatesMapViewState();
}

class _CoordinatesMapViewState extends State<CoordinatesMapView> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  void _initializeMap() {
    if (widget.points.isEmpty) {
      setState(() {
        _errorMessage = 'No coordinates available to display on map.';
      });
      return;
    }

    // Filter out invalid coordinates
    final validPoints = widget.points.where((point) {
      return CoordinateConverter.isValidCoordinates(
        point.y,
        point.x,
        format: widget.coordinateFormat,
      );
    }).toList();

    if (validPoints.isEmpty) {
      setState(() {
        _errorMessage = 'No valid coordinates found in the selected format.';
      });
      return;
    }

    // Create markers from valid coordinates
    final markers = validPoints.map((point) {
      final latLng = CoordinateConverter.localToWgs84(
        point.y,
        point.x,
        format: widget.coordinateFormat,
      );

      return Marker(
        markerId: MarkerId('${point.y},${point.x}'),
        position: latLng,
        infoWindow: InfoWindow(
          title: 'Point ${point.comment}',
          snippet: CoordinateConverter.formatCoordinates(
            point.y,
            point.x,
            point.z,
            widget.coordinateFormat,
          ),
        ),
      );
    }).toSet();

    setState(() {
      _markers = markers;
    });

    // Center the map on the first valid point
    if (_mapController != null && validPoints.isNotEmpty) {
      final firstPoint = validPoints.first;
      final latLng = CoordinateConverter.localToWgs84(
        firstPoint.y,
        firstPoint.x,
        format: widget.coordinateFormat,
      );
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(latLng, 15),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coordinates on Map'),
      ),
      body: _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            )
          : GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(0, 0),
                zoom: 2,
              ),
              markers: _markers,
              onMapCreated: (controller) {
                _mapController = controller;
                _initializeMap();
              },
            ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
