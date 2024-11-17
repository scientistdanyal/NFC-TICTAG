import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:provider/provider.dart';
import '../providers/api_provider.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'navigation_drawer.dart' as custom_drawer;
import 'package:google_fonts/google_fonts.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  static const platform = MethodChannel('com.example.sms');
  static const platform1 = MethodChannel('com.example.nfc');
  bool _isLoading = false;
  bool _isCallInProgress = false; // Track if a call is in progress
  String _nfcTagData = 'No NFC tag detected';
  List<String> phones = []; // Array to store phone numbers
  List therapies = [];
  List pathologies = [];
  String message = ''; // Variable to store message
  String tagType = '';

  @override
  void initState() {
    super.initState();
    _requestSmsPermission(); // Request SMS permission when the widget initializes
    _setupNfcListener(); // Set up NFC listener
  }

  void _setupNfcListener() {
    platform1.setMethodCallHandler((call) async {
      if (call.method == 'onNfcDetected') {
        String tagData = call.arguments;
        print("Scanned Tag data :$tagData");
        setState(() {
          _nfcTagData = tagData;
        });
        var apiProvider = Provider.of<APIProvider>(context, listen: false);
        var res = await apiProvider.getTagByNumber(_nfcTagData);
        print("Information to be handled :$res");

        if (res != null && res["information"] != null) {
          var information = res["information"];
          tagType = res["tagType"];
          var phone1 = information['phone1'] as String?;
          var phone2 = information['phone2'] as String?;
          var phone3 = information['phone3'] as String?;
          message = information['message'];
          if (tagType == 'elderly') {
            therapies = information['therapies'];
            pathologies = information['pathologies'];
          }

          phones = [phone1, phone2, phone3]
              .where((phone) => phone != null)
              .cast<String>()
              .toList();
        } else {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text("Alert"),
                content: const Text("Sorry! This Tag is not Linked."),
                actions: [
                  TextButton(
                    child: const Text("OK"),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1f6c85), // Set background color to 0xFF1f6c85
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent, // Ensure scaffold is transparent
        appBar: AppBar(
          title: const Text('Dashboard'),
          backgroundColor: const Color(0xFF1f6c85),
          elevation: 0,
          foregroundColor: Colors.white,
        ),
        drawer: custom_drawer.NavigationDrawer(),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _body(),
      ),
    );
  }

  Widget _body() {
    return Padding(
      padding:
          const EdgeInsets.all(20.0), // Small margin around the white container
      child: Container(
        height: double.infinity, // Allow the container to take the full height
        padding: const EdgeInsets.all(15.0), // Inner padding
        decoration: BoxDecoration(
          color: const Color(0xFFB9C6CB), // Background color of the container
          borderRadius: BorderRadius.circular(20.0), // Rounded corners
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1), // Shadow color
              blurRadius: 8.0, // Shadow blur
              offset: const Offset(0, 4), // Shadow offset
            ),
          ],
        ),
        child: _navigateButtons(),
      ),
    );
  }

  Widget _dummyButton(String text) {
    text = text.toUpperCase() + " TAG";
    return SizedBox(
      width: double.infinity, // Make the dummy button stretch to full width
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFF1f6c85), // Match body background color
          borderRadius: BorderRadius.circular(30), // Rounded corners
        ),
        child: Center(
          child: Text(
            text, // No 'const' here
            style: TextStyle(
              fontSize: !text.contains('DUMMY') ? 20 : 0,
              fontWeight: FontWeight.w900,
              color: const Color.fromARGB(255, 255, 255, 255),
            ),
          ),
        ), // Make text invisible but keep the widget
      ),
    );
  }

  Widget _navigateButtons() {
    // Get the orientation of the device (portrait or landscape)
    bool isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    return isPortrait
        ? _buildPortraitLayout() // Use flex layout in portrait mode
        : _buildLandscapeLayout(); // Use scrollable layout with space in landscape mode
  }

// Layout for portrait mode (use space around)
  Widget _buildPortraitLayout() {
    return Column(
      mainAxisAlignment:
          MainAxisAlignment.spaceAround, // Evenly distribute buttons
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _dummyButton(tagType),
        _navButton('CHIAMATA ICE', Icons.call, () async {
          for (String phone in phones) {
            await _waitForCallCompletion();
            print('Calling phone: $phone');
            await _makePhoneCall(phone);
            await Future.delayed(const Duration(seconds: 3));
          }
        }, '#009DE0'),
        _navButton('MESSAGGIO ICE', Icons.message, () async {
          setState(() {
            _isLoading = true;
          });
          try {
            String mapUrl = await _determinePosition();
            for (String phone in phones) {
              await _sendSMS(
                  "$message. Check out the location: $mapUrl", phone);
              await Future.delayed(const Duration(seconds: 3));
            }
          } finally {
            setState(() {
              _isLoading = false;
            });
          }
        }, '#FFDA02'),
        _navButton('CHIAMATA 112', Icons.local_police, () async {
          await _waitForCallCompletion();
          await _makePhoneCall("112");
        }, '#E2021A'),
        if (tagType == 'elderly') ...[
          _navButton('TERAPIE', Icons.local_police, () async {
            _showTherapies(context);
          }, '#19FF00'),
        ],
        if (tagType == 'elderly') ...[
          _navButton('PATOLOGIE', Icons.local_police, () async {
            _showPathologies(context);
          }, '#19FF00'),
        ],
        _dummyButton('dummy'),
      ],
    );
  }

// Layout for landscape mode (scrollable with spacing between buttons)
  Widget _buildLandscapeLayout() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _dummyButton(tagType),
          const SizedBox(height: 20), // Add space between buttons
          _navButton('CHIAMATA ICE', Icons.call, () async {
            for (String phone in phones) {
              await _waitForCallCompletion();
              print('Calling phone: $phone');
              await _makePhoneCall(phone);
              await Future.delayed(const Duration(seconds: 3));
            }
          }, '#009DE0'),
          const SizedBox(height: 20), // Add space between buttons
          _navButton('MESSAGGIO ICE', Icons.message, () async {
            setState(() {
              _isLoading = true;
            });
            try {
              String mapUrl = await _determinePosition();
              for (String phone in phones) {
                await _sendSMS(
                    "$message. Check out the location: $mapUrl", phone);
                await Future.delayed(const Duration(seconds: 3));
              }
            } finally {
              setState(() {
                _isLoading = false;
              });
            }
          }, '#FFDA02'),
          const SizedBox(height: 20), // Add space between buttons
          _navButton('CHIAMATA 112', Icons.local_police, () async {
            await _waitForCallCompletion();
            await _makePhoneCall("112");
          }, '#E2021A'),

          if (tagType == 'elderly') ...[
            const SizedBox(height: 20), // Add space between buttons

            _navButton('TERAPIE', Icons.local_police, () async {
              print("Show Therapies");
            }, '#19FF00'),
          ],
          if (tagType == 'elderly') ...[
            const SizedBox(height: 20),
            _navButton('PATOLOGIE', Icons.local_police, () async {
              print("Show PATOLOGIE");
            }, '#19FF00'),
          ],
          const SizedBox(height: 20), // Add space between buttons
          _dummyButton("dummy"),
        ],
      ),
    );
  }

  Widget _navButton(
      String text, IconData icon, VoidCallback onPressed, String borderColor) {
    if (tagType == 'elderly' && text.contains('112')) {
      text = '112';
    }
    double mrgn = text == '112' ? 100.0 : 16.0;
    return SizedBox(
      height: text == '112' ? 130 : 90,
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
              color: Color(int.parse('0xff${borderColor.replaceAll('#', '')}')),
              width: 15), // Red border
          borderRadius: BorderRadius.circular(
              text == '112' ? 100 : 30), // Rounded corners
        ),
        margin: EdgeInsets.symmetric(horizontal: mrgn), // Add horizontal margin
        child: ElevatedButton.icon(
          onPressed: onPressed,
          label: Text(
            text.toUpperCase(), // Convert text to uppercase
            style: GoogleFonts.poppins(
              color: text == '112' ? Colors.red : Colors.white,
              fontSize: text == '112' ? 30 : 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: text == '112'
                ? const Color.fromARGB(255, 255, 255, 255)
                : const Color(0xFF686868),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
            elevation: 0, // Remove shadow to make the border visible
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                  text == '112' ? 50 : 15), // Small internal border radius
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendSMS(String message, String recipients) async {
    await _requestSmsPermission();
    try {
      final result = await platform.invokeMethod('sendSms', {
        'phoneNumber': recipients,
        'message': message,
      });
      print(result);
      _showAlert('Success', 'SMS sent successfully');
    } on PlatformException catch (e) {
      print("Failed to send SMS: '${e.message}'");
      _showAlert('Error', 'Failed to send SMS: ${e.message}');
    }
  }

  Future<void> _requestSmsPermission() async {
    final status = await Permission.sms.request();
    if (!status.isGranted) {
      _showAlert(
          'Permission Denied', 'SMS permission is required to send SMS.');
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    try {
      _isCallInProgress = true;
      await FlutterPhoneDirectCaller.callNumber(phoneNumber);
    } catch (e) {
      print("Error making phone call: $e");
    } finally {
      _isCallInProgress = false;
    }
  }

  Future<void> _waitForCallCompletion() async {
    while (_isCallInProgress) {
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  Future<String> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showAlert(
          'Error', 'Location services are disabled. Please enable them.');
      return '';
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showAlert('Permission Denied', 'Location permission is required.');
        return '';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showAlert('Permission Denied Forever',
          'Location permissions are permanently denied.');
      return '';
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    String mapUrl =
        "http://maps.google.com/?q=${position.latitude},${position.longitude}";
    return mapUrl;
  }

  void _showTherapies(BuildContext context) {
    print("Therapies here : $therapies");
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Therapies Table'),
          content: SingleChildScrollView(
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Therapy')),
                DataColumn(label: Text('Medication')),
              ],
              rows: therapies.where((therapyData) {
                // Only include rows where at least one of the fields is not empty
                return therapyData['therapy']!.isNotEmpty ||
                    therapyData['medication']!.isNotEmpty;
              }).map((therapyData) {
                return DataRow(
                  cells: [
                    DataCell(Text(therapyData['therapy'] ?? '')),
                    DataCell(Text(therapyData['medication'] ?? '')),
                  ],
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showPathologies(BuildContext context) {
    print("Pathologies here : $pathologies");
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pathologies Table'),
          content: SingleChildScrollView(
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Pathology')),
              ],
              rows: pathologies.where((pathoData) {
                // Only include rows where at least one of the fields is not empty
                return pathoData['pathology']!.isNotEmpty;
              }).map((pathoData) {
                return DataRow(
                  cells: [
                    DataCell(Text(pathoData['pathology'] ?? '')),
                  ],
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
