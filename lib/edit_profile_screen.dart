import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class EditProfileScreen extends StatefulWidget {
  final String currentName;
  final String currentEmail;
  final String currentPhone;

  const EditProfileScreen({
    super.key,
    required this.currentName,
    required this.currentEmail,
    required this.currentPhone,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  
  File? _imageFile;
  String? _currentImageUrl;
  bool _isUpdating = false;
  final goldColor = const Color(0xFFD4AF37);

  // KONSTANTA BACKEND (WAJIB SESUAI REQUEST)
  static const String serverIp = '192.168.11.192';
  static const String baseUrl = 'http://192.168.11.192';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _emailController = TextEditingController(text: widget.currentEmail);
    _phoneController = TextEditingController(text: widget.currentPhone);
    _loadCurrentImage();
  }

  Future<void> _loadCurrentImage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentImageUrl = prefs.getString('userImage');
    });
  }

  String _fixImageUrl(String url) {
    if (url.contains('localhost')) {
      return url.replaceAll('localhost', serverIp);
    } else if (url.contains('127.0.0.1')) {
      return url.replaceAll('127.0.0.1', serverIp);
    }
    return url;
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  Future<void> _handleUpdate() async {
    if (_nameController.text.isEmpty) return;

    setState(() => _isUpdating = true);
    final prefs = await SharedPreferences.getInstance();
    final int? userId = prefs.getInt('userId');

    if (userId == null) {
      setState(() => _isUpdating = false);
      _showSnackBar("Sesi berakhir, silakan login ulang", Colors.red);
      return;
    }

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/update-profile'),
    );

    request.fields['user_id'] = userId.toString();
    request.fields['name'] = _nameController.text;
    request.fields['email'] = _emailController.text;
    request.fields['phone'] = _phoneController.text;

    if (_imageFile != null) {
      request.files.add(await http.MultipartFile.fromPath('image', _imageFile!.path));
    }

    try {
      final streamedResponse = await request.send().timeout(const Duration(seconds: 20));
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        final userData = data['user'];
        
        String? finalImageUrl = userData['image_url'];
        if (finalImageUrl != null) {
          finalImageUrl = _fixImageUrl(finalImageUrl);
        }

        await prefs.setString('userName', userData['name']);
        await prefs.setString('userEmail', userData['email']);
        await prefs.setString('userPhone', userData['phone']);

        if (finalImageUrl != null) {
          await prefs.setString('userImage', finalImageUrl);
        }

        if (mounted) {
          setState(() => _isUpdating = false);
          _showSnackBar("Profil Berhasil Diperbarui!", Colors.green);
          Navigator.pop(context, true); 
        }
      } else {
        setState(() => _isUpdating = false);
        _showSnackBar(data['message'] ?? "Gagal memperbarui", Colors.red);
      }
    } catch (e) {
      setState(() => _isUpdating = false);
      _showSnackBar("Koneksi Gagal ke Server", Colors.red);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Edit Profil', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_isUpdating)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD4AF37)))),
            )
          else
            TextButton(
              onPressed: _handleUpdate,
              child: Text('SIMPAN', style: TextStyle(color: goldColor, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[800],
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!)
                        : (_currentImageUrl != null && _currentImageUrl!.isNotEmpty
                            ? NetworkImage(_fixImageUrl(_currentImageUrl!))
                            : const NetworkImage('https://i.pravatar.cc/150?u=user')) as ImageProvider,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: goldColor, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt, color: Colors.black, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            _buildTextField('Nama Lengkap', _nameController, Icons.person_outline),
            const SizedBox(height: 20),
            _buildTextField('Email', _emailController, Icons.email_outlined),
            const SizedBox(height: 20),
            _buildTextField('Nomor HP', _phoneController, Icons.phone_android_outlined),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: goldColor, size: 20),
            filled: true,
            fillColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}
