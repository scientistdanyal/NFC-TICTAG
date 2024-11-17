import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white, // White background
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: const Color(0xFF1f6c85),
          elevation: 0,
          foregroundColor: Colors.white,
        ),
        backgroundColor: Colors.transparent,
        body: _profileContent(),
      ),
    );
  }

  Widget _profileContent() {
    // User profile information
    final user = {
      'name': 'Faisal',
      'surname': 'Rehman',
      'email': 'faisalrihman199@gmail.com',
      'profilePicture':
          'assets/profile_picture.png' // Replace with actual asset or URL
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundImage: AssetImage(user['profilePicture']!),
              radius: 60,
              backgroundColor: Colors.grey[200],
            ),
            const SizedBox(height: 20),
            Text(
              '${user['name']} ${user['surname']}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1f6c85), // Purplish color
              ),
            ),
            const SizedBox(height: 10),
            Text(
              user['email']!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
