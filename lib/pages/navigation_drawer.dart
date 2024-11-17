import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/api_provider.dart';
import 'login_page.dart';
import 'dashboard_page.dart';
import 'card_page.dart';
import 'NFCScanPage.dart';

class NavigationDrawer extends StatelessWidget {
  const NavigationDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final apiProvider = Provider.of<APIProvider>(context, listen: false);

    return FutureBuilder<Map<String, dynamic>?>(
      future: apiProvider.getUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Error loading user data'));
        }

        final user = snapshot.data;
        print("User is : $user");
        // Use the null-aware operator to safely access user fields
        final userName = user?['email'] ?? '';

        return Drawer(
          child: Container(
            color: const Color(0xFF1f6c85), // Purplish drawer background
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                DrawerHeader(
                  decoration: const BoxDecoration(
                    color: Color(0xFF1f6c85), // Purplish header background
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 30,
                        child: Icon(Icons.person,
                            size: 40, color: Color(0xFF1f6c85)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$userName ',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: () {
                          _launchURL(
                              'https://app.tictag.it/profile'); // Redirect to Google
                        },
                      ),
                    ],
                  ),
                ),
                _drawerItem(
                  icon: Icons.home,
                  text: 'Home',
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => DashboardPage()),
                    );
                  },
                ),
                _drawerItem(
                  icon: Icons.credit_card,
                  text: 'Cards',
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const CardPage()),
                    );
                  },
                ),
                // Conditionally add "Tag QR" for admin users
                if (user != null && user['role'] == 'admin')
                  _drawerItem(
                    icon: Icons.qr_code,
                    text: 'Tag QR',
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => NFCScanPage()),
                      );
                    },
                  ),
                _drawerItem(
                  icon: Icons.logout,
                  text: 'Logout',
                  onTap: () async {
                    await apiProvider.logout();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginPage()),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _launchURL(String link) async {
    final Uri url = Uri.parse(link);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  Widget _drawerItem(
      {required IconData icon,
      required String text,
      GestureTapCallback? onTap}) {
    return ListTile(
      title: Row(
        children: <Widget>[
          Icon(icon, color: Colors.white),
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          )
        ],
      ),
      onTap: onTap,
    );
  }

  Future<void> _launchInBrowser(Uri url) async {
    if (!await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not launch $url');
    }
  }
}
