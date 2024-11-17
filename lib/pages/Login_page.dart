import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/api_provider.dart';
import 'dashboard_page.dart'; // Import the dashboard page
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool _isLoading = false; // Loading state

  Future<void> _launchURL(String link) async {
    final Uri url = Uri.parse(link);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      constraints.maxHeight, // Minimum height to avoid overflow
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: IntrinsicHeight(
                    // Makes the column take up minimum necessary space
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                            child:
                                _icon()), // Flexible used to prevent overflow
                        const SizedBox(height: 50),
                        _inputField("Username", usernameController),
                        const SizedBox(height: 20),
                        _inputField("Password", passwordController,
                            isPassword: true),
                        const SizedBox(height: 50),
                        _loginBtn(),
                        const SizedBox(height: 20),
                        _extraText(),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _icon() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF1f6c85), width: 2),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.person, color: Color(0xFF1f6c85), size: 120),
    );
  }

  Widget _inputField(String hintText, TextEditingController controller,
      {bool isPassword = false}) {
    var border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFF1f6c85)),
    );

    return TextField(
      style: const TextStyle(color: Color(0xFF1f6c85)),
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFF1f6c85)),
        enabledBorder: border,
        focusedBorder: border,
      ),
      obscureText: isPassword,
    );
  }

  Widget _loginBtn() {
    return GestureDetector(
      onTap: () async {
        if (_isLoading) return; // Prevent multiple taps
        setState(() {
          _isLoading = true; // Set loading state
        });

        final apiProvider = Provider.of<APIProvider>(context, listen: false);
        try {
          final response = await apiProvider.login({
            'email': usernameController.text,
            'password': passwordController.text,
          });

          print('Login Response: $response'); // Log response for debugging

          if (response['success'] == true) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => DashboardPage()),
            );
          } else {
            _showErrorDialog(
                'Login Failed', response['message'] ?? 'Login failed');
          }
        } catch (e) {
          _showErrorDialog('Error', 'An error occurred:');
        } finally {
          setState(() {
            _isLoading = false; // Reset loading state
          });
        }
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1f6c85), Color(0xFF1f6c85)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_isLoading)
                const CircularProgressIndicator(color: Colors.white),
              if (!_isLoading)
                const Text(
                  "Sign in",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
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

  Widget _extraText() {
    return Column(
      children: [
        const Text(
          "Can't access to your account?",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Color(0xFF1f6c85)),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () {
            _launchURL("https://app.tictag.it/register");
          },
          child: const Text(
            "Sign up here",
            style: TextStyle(fontSize: 16, color: Color(0xFF1f6c85)),
          ),
        ),
      ],
    );
  }
}
