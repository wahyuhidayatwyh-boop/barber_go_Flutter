import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart'; 
import 'register_screen.dart';
import 'home_screen.dart';
import 'notification_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final goldColor = const Color(0xFFD4AF37);
  bool _isLoading = false;
  final String _serverIp = '192.168.11.192'; // IP Laptop Anda

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('Email dan Password tidak boleh kosong');
      return;
    }

    setState(() => _isLoading = true);
    
    final String apiUrl = 'http://$_serverIp/api/login';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text,
          'password': _passwordController.text,
        }),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        final userData = data['user'];
        
        await prefs.setBool('isLoggedIn', true);
        await prefs.setInt('userId', userData['id']);
        await prefs.setString('userName', userData['name']);
        await prefs.setString('userEmail', userData['email']);
        await prefs.setString('userPhone', userData['phone'] ?? '');

        // --- BAGIAN PENTING: SIMPAN URL FOTO PROFIL ---
        String? imageUrl = userData['image_url'];
        if (imageUrl != null) {
          // Ganti localhost/127.0.0.1 menjadi IP Laptop
          imageUrl = imageUrl.replaceAll('localhost', _serverIp).replaceAll('127.0.0.1', _serverIp);
        }
        await prefs.setString('userImage', imageUrl ?? '');

        await NotificationService.showNotification(
          id: 1,
          title: 'Login Berhasil',
          body: 'Selamat datang kembali, ${userData['name']}!',
        );

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        }
      } else {
        _showError(data['message'] ?? 'Email atau Password salah');
      }
    } catch (e) {
      _showError('Gagal terhubung ke server (IP: $_serverIp)');
      debugPrint("Login Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.45,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1503951914875-452162b0f3f1?q=80&w=1000'),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.2), const Color(0xFF121212)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.content_cut, color: goldColor, size: 48),
                        const SizedBox(height: 8),
                        const Text(
                          'CUKURMEN',
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80),
                  const Text('Selamat Datang', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  Text('Silakan login untuk memesan layanan', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14)),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      children: [
                        _buildTextField(controller: _emailController, label: 'Email', icon: Icons.email_outlined),
                        const SizedBox(height: 20),
                        _buildTextField(controller: _passwordController, label: 'Password', icon: Icons.lock_outline, isPassword: true),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: goldColor,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isLoading 
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                              : const Text('MASUK SEKARANG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen())),
                      child: RichText(
                        text: TextSpan(
                          text: 'Belum punya akun? ',
                          style: const TextStyle(color: Colors.white60),
                          children: [
                            TextSpan(text: 'Daftar', style: TextStyle(color: goldColor, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38, fontSize: 14),
        prefixIcon: Icon(icon, color: goldColor, size: 22),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: goldColor)),
      ),
    );
  }
}
