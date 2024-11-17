import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class APIProvider with ChangeNotifier {
  static const String _baseUrl = 'https://api.tictag.it/api';

  Map<String, String>? _headers;

  APIProvider() {
    _loadUser();
  }

  Future<void> _loadUser() async {
    final savedUser = await _getSavedUser();
    if (savedUser != null) {
      _headers = {
        'Authorization': 'Bearer ${savedUser['token']}',
        'Content-Type': 'application/json',
      };
    } else {
      _headers = null;
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>?> _getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson != null) {
      return jsonDecode(userJson);
    }
    return null;
  }

  Future<Map<String, dynamic>?> getUser() async {
    return await _getSavedUser();
  }

  Future<void> _saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('user', jsonEncode(user));
  }

  Future<void> _removeUser() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('user');
  }

  Future<Map<String, dynamic>> login(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    final responseData = jsonDecode(response.body);
    if (responseData['success']) {
      await _saveUser(responseData['data']);
      _headers = {
        'Authorization': 'Bearer ${responseData['data']['token']}',
        'Content-Type': 'application/json',
      };
    }
    notifyListeners();

    // After login is successful, fetch the tag by its number
    await fetchAllTags();

    return responseData;
  }

  Future<void> logout() async {
    await _removeUser();
    _headers = null;
    notifyListeners();
  }

  Future<Map<String, dynamic>> addTag(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/tags/add'),
      headers: _headers,
      body: jsonEncode(data),
    );
    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return responseData;
    } else {
      throw Exception('Failed to add tag: ${responseData['message']}');
    }
  }

  Future<Map<String, dynamic>> fetchAllTags() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/tags/all'),
      headers: _headers,
    );
    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      // Extract the tagNumber, tagType, and information and save in SharedPreferences
      List<Map<String, dynamic>> tagsToSave = [];
      List<dynamic> tags = responseData['data'];

      for (var tag in tags) {
        final tagInfo = await getTagInfo(tag['tagNumber'], "admin123");
        tagsToSave.add({
          'tagNumber': tag['tagNumber'],
          'tagType': tag['tagType'],
          'information': tagInfo,
        });
      }

      // Save the tags in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('tags', jsonEncode(tagsToSave));

      return responseData;
    } else {
      throw Exception('Failed to fetch tags: ${responseData['message']}');
    }
  }

  Future<Map<String, dynamic>> getTagInfo(
      String tagNumber, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/tags/info'),
      headers: _headers,
      body: jsonEncode({
        'tagNumber': tagNumber,
        'password': password,
      }),
    );

    final responseData = jsonDecode(response.body);
    if (response.statusCode == 200 && responseData['success']) {
      await _saveTag(responseData['data']);
      return responseData['data'];
    } else {
      throw Exception(
          'Failed to retrieve tag info: ${responseData['message']}');
    }
  }

  Future<Map<String, dynamic>?> getDecryptedTagInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final infoJson = prefs.getString('tag');
    if (infoJson != null) {
      return jsonDecode(infoJson);
    }
    return null;
  }

  // Save a single tag into SharedPreferences
  Future<void> _saveTag(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('tag', jsonEncode(data));
  }

  // Public getter for _headers
  Map<String, String>? get headers => _headers;

  // Method to get the complete tag (tagNumber, tagType, and information) based on tagNumber
  Future<Map<String, dynamic>?> getTagByNumber(String tagNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final tagsJson = prefs.getString('tags');

    if (tagsJson != null) {
      List<dynamic> decodedTags = jsonDecode(tagsJson);
      List<Map<String, dynamic>> tags =
          decodedTags.cast<Map<String, dynamic>>();

      // Search for the tagNumber
      for (var tag in tags) {
        if (tag['tagNumber'] == tagNumber) {
          return tag; // Return the entire tag object
        }
      }
    }

    // Return null if no matching tag is found
    return null;
  }

  // Method to retrieve all saved tags
  Future<List<Map<String, dynamic>>?> getSavedTags() async {
    final prefs = await SharedPreferences.getInstance();
    final tagsJson = prefs.getString('tags');

    if (tagsJson != null) {
      List<dynamic> decodedTags = jsonDecode(tagsJson);
      return decodedTags.cast<Map<String, dynamic>>();
    }

    return null;
  }
}
