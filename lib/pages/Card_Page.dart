import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/api_provider.dart';
import 'navigation_drawer.dart' as custom_drawer;

class CardPage extends StatefulWidget {
  const CardPage({super.key});

  @override
  _CardPageState createState() => _CardPageState();
}

class _CardPageState extends State<CardPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<dynamic> _nfcTags = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTags();
  }

  Future<void> _fetchTags() async {
    final apiProvider = Provider.of<APIProvider>(context, listen: false);
    try {
      final response = await apiProvider.fetchAllTags();
      if (response['success']) {
        setState(() {
          _nfcTags = response['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      // Handle the error
      setState(() {
        _isLoading = false;
      });
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
          title: const Text('NFC Tags'),
          backgroundColor: const Color(0xFF1f6c85),
          elevation: 0,
          foregroundColor: Colors.white,
        ),
        backgroundColor: Colors.transparent,
        drawer: custom_drawer.NavigationDrawer(),
        body: Column(
          children: [
            _searchBar(),
            Expanded(child: _isLoading ? _buildLoader() : _nfcCardList()),
          ],
        ),
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
        decoration: InputDecoration(
          hintText: 'Search NFC Tag by Number...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF1f6c85)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF1f6c85)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF1f6c85)),
          ),
        ),
      ),
    );
  }

  Widget _nfcCardList() {
    List<dynamic> filteredTags = _nfcTags.where((tag) {
      return tag["tagNumber"].toLowerCase().contains(_searchQuery);
    }).toList();

    return ListView.builder(
      itemCount: filteredTags.length,
      itemBuilder: (context, index) {
        final tag = filteredTags[index];
        return TagCard(tag: tag);
      },
    );
  }

  Widget _buildLoader() {
    return const Center(child: CircularProgressIndicator());
  }
}

class TagCard extends StatefulWidget {
  final Map<String, dynamic> tag;

  const TagCard({super.key, required this.tag});

  @override
  _TagCardState createState() => _TagCardState();
}

class _TagCardState extends State<TagCard> {
  bool _isInformationVisible = false;
  bool _isLoading = false;

  void _promptForPassword(BuildContext context) {
    TextEditingController passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Password'),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(hintText: 'Enter your password'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Submit'),
              onPressed: () async {
                String password = passwordController.text;
                if (password.isNotEmpty) {
                  Navigator.of(context).pop();
                  _fetchTagInfo(password);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _fetchTagInfo(String password) async {
    setState(() {
      _isLoading = true;
    });

    final apiProvider = Provider.of<APIProvider>(context, listen: false);
    try {
      final tagInfo =
          await apiProvider.getTagInfo(widget.tag['tagNumber'], password);
      print(tagInfo);

      // Save decrypted information to local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('decryptedTagInfo', jsonEncode(tagInfo));

      setState(() {
        widget.tag['phone1'] = tagInfo['phone1']; // Update state directly
        widget.tag['phone2'] = tagInfo['phone2'];
        widget.tag['phone3'] = tagInfo['phone3'];
        widget.tag['message'] = tagInfo['message'];

        _isInformationVisible = true;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Tag information decrypted successfully!')),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Failed to decrypt tag information: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        leading: const Icon(Icons.nfc, color: Color(0xFF1f6c85), size: 40),
        title: Text(
          'Tag Number: ${widget.tag["tagNumber"]}',
          style: const TextStyle(
            color: Color(0xFF1f6c85),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tag Type: ${widget.tag["tagType"]}',
              style: const TextStyle(
                color: Color(0xFF1f6c85),
                fontSize: 16,
              ),
            ),
            if (_isInformationVisible && !_isLoading)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Phone 1: ${widget.tag["phone1"] ?? 'N/A'}'),
                  Text('Phone 2: ${widget.tag["phone2"] ?? 'N/A'}'),
                  Text('Phone 3: ${widget.tag["phone3"] ?? 'N/A'}'),
                  Text('Message: ${widget.tag["message"] ?? 'N/A'}'),
                ],
              ),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
          ],
        ),
        trailing: TextButton(
          onPressed: () {
            if (_isInformationVisible) {
              setState(() {
                _isInformationVisible = false;
              });
            } else {
              _promptForPassword(context);
            }
          },
          child: Text(
            _isInformationVisible ? 'Hide' : 'Show',
            style: const TextStyle(
              color: Color(0xFF1f6c85),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        contentPadding: const EdgeInsets.all(16),
        onTap: () {
          _showTagDetails(widget.tag);
        },
      ),
    );
  }

  void _showTagDetails(Map<String, dynamic> tag) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('NFC Tag Details'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Tag Number: ${tag["tagNumber"]}'),
              Text('Tag Type: ${tag["tagType"]}'),
              if (_isInformationVisible)
                Text('Information: ${tag["information"]}'),
            ],
          ),
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
