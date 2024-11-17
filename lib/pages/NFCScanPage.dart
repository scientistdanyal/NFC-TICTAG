import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:provider/provider.dart'; // Import provider for state management
import 'navigation_drawer.dart' as custom_drawer;

import '../providers/api_provider.dart';

class NFCScanPage extends StatefulWidget {
  const NFCScanPage({super.key});

  @override
  _NFCScanPageState createState() => _NFCScanPageState();
}

class _NFCScanPageState extends State<NFCScanPage> {
  bool _isScanning = false;
  String _nfcTagData = 'No NFC tag detected';

  Future<void> _startNFCScan() async {
    setState(() {
      _isScanning = true;
    });

    try {
      final tag = await FlutterNfcKit.poll();
      setState(() {
        print("Detected Tag is : ${tag.id}");
        _nfcTagData = tag.id;
      });

      // Call addTag API here
      await _addTagToServer(tag.id);

      await FlutterNfcKit.finish();
    } catch (e) {
      print("Error reading NFC tag: $e");
      setState(() {
        _nfcTagData = 'Error reading NFC tag';
      });
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  void showAlert(BuildContext context, String text) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Tag Status'),
          content: Text(text),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Function to add tag to server using APIProvider
  Future<void> _addTagToServer(String tagId) async {
    try {
      final apiProvider = Provider.of<APIProvider>(context, listen: false);
      final response = await apiProvider.addTag({'tagNumber': tagId});

      if (response['success']) {
        showAlert(context, response['message']);
        print("Tag successfully added to server: ${response['data']}");
      } else {
        showAlert(context, response['message']);
        print("Failed to add tag: ${response['message']}");
      }
    } catch (e) {
      showAlert(context, "Error while Saving NFC Tag");
      print("Error adding tag to server: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white, // White background
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('NFC Scan'),
          backgroundColor: const Color(0xFF1f6c85),
          elevation: 0,
          foregroundColor: Colors.white,
        ),
        backgroundColor: Colors.transparent,
        drawer: custom_drawer.NavigationDrawer(), // Use the custom drawer
        body: SingleChildScrollView(
          // Make the body scrollable
          child: Container(
            height: MediaQuery.of(context).size.height, // Full height of screen
            child: Center(
              // Center content vertically
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center, // Center content vertically
                  crossAxisAlignment:
                      CrossAxisAlignment.center, // Center content horizontally
                  children: [
                    _nfcIcon(),
                    const SizedBox(height: 50),
                    _scanButton(),
                    const SizedBox(height: 20),
                    Text(
                      'Last Added Tag ID: $_nfcTagData',
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _nfcIcon() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
            color: const Color(0xFF1f6c85), width: 2), // Purplish border
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.nfc,
          color: Color(0xFF1f6c85), size: 120), // Purplish icon
    );
  }

  Widget _scanButton() {
    return SizedBox(
      width: double.infinity, // Full width button
      child: ElevatedButton.icon(
        onPressed: _startNFCScan,
        icon: const Icon(Icons.scanner, color: Colors.white),
        label: _isScanning
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('Scan NFC TAG',
                style: TextStyle(color: Colors.white)), // White text
        style: ElevatedButton.styleFrom(
          backgroundColor:
              const Color(0xFF1f6c85), // Purplish button background
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          shape: const StadiumBorder(),
        ),
      ),
    );
  }
}
