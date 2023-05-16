import 'package:exprollable_page_view/exprollable_page_view.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps_example/locations.dart' as locations;

void main() {
  runApp(const MapsExample());
}

class MapsExample extends StatefulWidget {
  const MapsExample({Key? key}) : super(key: key);

  @override
  State createState() => _MapsExampleState();
}

class _MapsExampleState extends State<MapsExample> {
  final Map<String, Marker> _markers = {};
  late final ExprollablePageController _pageController;
  GoogleMapController? _mapController;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    const peekOffset = ViewportInset.fractional(0.7);
    _pageController = ExprollablePageController(
      viewportConfiguration: ViewportConfiguration(
        extraSnapInsets: [peekOffset],
      ),
    );
  }

  Future<void> onMapCreated(GoogleMapController controller) async {
    _mapController = controller;
    final googleOffices = await locations.getGoogleOffices();
    setState(() {
      _markers.clear();
      for (final office in googleOffices.offices) {
        final marker = Marker(
          markerId: MarkerId(office.name),
          position: LatLng(office.lat, office.lng),
          onTap: () => onMarkerTapped(office.name),
          infoWindow: InfoWindow(
            title: office.name,
            snippet: office.address,
          ),
        );
        _markers[office.name] = marker;
      }
    });
  }

  void onMarkerTapped(String officeName) async {
    if (_isAnimating) return;
    final index = _markers.keys.toList().indexOf(officeName);
    _isAnimating = true;
    debugPrint("Animate to $officeName");
    await _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
    _isAnimating = false;
  }

  void onPageChanged(int page) async {
    if (_isAnimating) return;
    final marker = _markers.values.elementAt(page);
    debugPrint("Animate to ${marker.infoWindow.title}");
    _isAnimating = true;
    await _mapController!
        .animateCamera(CameraUpdate.newLatLng(marker.position));
    _isAnimating = false;
    _mapController!.showMarkerInfoWindow(marker.mapsId);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Maps Example"),
          backgroundColor: Colors.green,
        ),
        bottomNavigationBar: buildBottomAppBar(),
        body: Stack(
          children: [
            GoogleMap(
              compassEnabled: false,
              onMapCreated: onMapCreated,
              initialCameraPosition: const CameraPosition(
                target: LatLng(0, 0),
                zoom: 2,
              ),
              markers: _markers.values.toSet(),
            ),
            if (_mapController == null)
              const Center(child: CircularProgressIndicator()),
            Offstage(
              offstage: _mapController == null,
              child: ExprollablePageView(
                onPageChanged: onPageChanged,
                controller: _pageController,
                itemCount: _markers.length,
                itemBuilder: buildPage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPage(BuildContext context, int page) {
    final marker = _markers.values.elementAt(page);
    return PageGutter(
      gutterWidth: 8,
      child: Card(
        margin: EdgeInsets.zero,
        child: ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: 30,
          controller: PageContentScrollController.of(context),
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(marker.infoWindow.title!),
              subtitle: Text(marker.infoWindow.snippet!),
            );
          },
        ),
      ),
    );
  }

  Widget buildBottomAppBar() {
    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: () {
              _mapController!.animateCamera(
                CameraUpdate.zoomOut(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: () {
              _mapController!.animateCamera(
                CameraUpdate.zoomIn(),
              );
            },
          ),
        ],
      ),
    );
  }
}
