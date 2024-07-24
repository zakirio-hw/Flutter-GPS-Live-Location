import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:trust_location/trust_location.dart';
import 'package:location/location.dart' as locationv2;
import 'cached_tile.dart';

class GeoMapOverlay extends StatefulWidget {
  const GeoMapOverlay({super.key});

  @override
  State<GeoMapOverlay> createState() => _GeoMapOverlayState();
}

class _GeoMapOverlayState extends State<GeoMapOverlay> {
  locationv2.Location lokasi = locationv2.Location();
  double _latitude = 0;
  double _longitude = 0;
  String? _address;
  bool isLoading = true;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    requestPermission();
    getLocation();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<bool> requestPermission() async {
    bool serviceEnabled;
    locationv2.PermissionStatus permissionGranted;
    serviceEnabled = await lokasi.serviceEnabled();

    // Mengecek servis
    if (!serviceEnabled) {
      serviceEnabled = await lokasi.requestService();
      if (!serviceEnabled) {
        return false;
      }
    }

    // Mengecek permission (izin)
    permissionGranted = await lokasi.hasPermission();
    if (permissionGranted == locationv2.PermissionStatus.denied) {
      permissionGranted = await lokasi.requestPermission();
      if (permissionGranted != locationv2.PermissionStatus.granted) {
        return false;
      }
    }

    return true;
  }

  Future<void> getLocation() async {
    final hasPermission = await requestPermission();
    if (!hasPermission) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Permission Denied'),
            content: const SingleChildScrollView(
              child: ListBody(
                children: [
                  Text(
                    "Tanpa izin penggunaan lokasi aplikasi ini tidak dapat digunakan dengan baik. Apa anda yakin menolak izin pengaktifan lokasi?",
                    style: TextStyle(fontSize: 18.0),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text('COBA LAGI'),
                onPressed: () {
                  Navigator.of(context).pop();
                  requestPermission();
                },
              ),
              TextButton(
                child: const Text('SAYA YAKIN'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } else {
      // Mengambil Lokasi
      TrustLocation.start(5);
      try {
        TrustLocation.onChange.listen((values) {
          var mockStatus = values.isMockLocation;
          if (mockStatus == true) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                'Fake GPS terdeteksi. Mohon non aktifkan fitur Fake GPS Anda',
              ),
            ));
            TrustLocation.stop();
            return;
          }

          if (mounted) {
            setState(() {
              isLoading = false;
              _latitude = double.parse(values.latitude.toString());
              _longitude = double.parse(values.longitude.toString());

              _mapController.move(LatLng(_latitude, _longitude), 13);
              getPlace();
            });
          }
        });
      } on PlatformException catch (e) {
        debugPrint('PlatformException $e');
      }
    }
  }

  void getPlace() async {
    List<Placemark> newPlace = await placemarkFromCoordinates(_latitude, _longitude);

    Placemark placeMark = newPlace[0];
    String name = placeMark.name.toString();
    String subLocality = placeMark.subLocality.toString();
    String locality = placeMark.locality.toString();
    String administrativeArea = placeMark.administrativeArea.toString();
    String postalCode = placeMark.postalCode.toString();
    String country = placeMark.country.toString();
    String address = "$name, $subLocality, $locality, $administrativeArea $postalCode, $country";

    setState(() {
      _address = address;
    });
  }

  Widget displayMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(_latitude, _longitude),
        initialZoom: 15,
        maxZoom: 19,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          tileProvider: CachedTileProvider(),
          subdomains: const ['a', 'b', 'c'],
          maxZoom: 19,
        ),
        MarkerLayer(
          markers: [
            Marker(
              width: 40.0,
              height: 40.0,
              point: LatLng(_latitude, _longitude),
              child: const FlutterLogo(),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Flutter Map"),
      ),
      body: Container(
        color: Colors.white,
        child: Stack(
          children: [
            Container(
              margin: const EdgeInsets.all(0),
              height: screenSize.height / 1.5,
              child: displayMap(),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: screenSize.height / 4,
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                margin: const EdgeInsets.only(left: 10, right: 10, bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    children: [
                      Visibility(
                        visible: isLoading,
                        child: const CircularProgressIndicator(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 10),
                      isLoading
                          ? const Text("Sedang mencari lokasi ...")
                          : Text("Lokasi anda adalah \nLat: $_latitude\nLong: $_longitude"),
                      Text("Alamat: \n$_address", textAlign: TextAlign.center),
                      const SizedBox(height: 20),
                      Visibility(
                        visible: !isLoading,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.lightBlue,
                          ),
                          onPressed: () {
                            setState(() {
                              isLoading = true;
                              _address = "";
                            });
                            getLocation();
                          },
                          icon: const Icon(Icons.my_location_outlined),
                          label: const Padding(
                            padding: EdgeInsets.all(15.0),
                            child: Text("Refresh Lokasi", style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
