import 'package:flutter/material.dart';
import 'booking_barber_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class BookingServiceScreen extends StatefulWidget {
  const BookingServiceScreen({super.key});

  @override
  State<BookingServiceScreen> createState() => _BookingServiceScreenState();
}

class _BookingServiceScreenState extends State<BookingServiceScreen> {
  Map<String, dynamic>? _selectedServiceData;
  final goldColor = const Color(0xFFD4AF37);
  
  List<dynamic> _services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    // Gunakan IP laptop Anda yang baru
    const String apiUrl = 'http://192.168.11.192/api/home-data';
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _services = data['services'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error ambil layanan: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pilih Layanan',
                style: TextStyle(color: onSurface, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(
                'Pilih layanan yang Anda inginkan hari ini',
                style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
            : _services.isEmpty 
              ? const Center(child: Text('Tidak ada layanan tersedia'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _services.length,
                  itemBuilder: (context, index) {
                    final service = _services[index];
                    final isSelected = _selectedServiceData?['id'] == service['id'];

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedServiceData = service;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: isSelected ? goldColor : Colors.white.withOpacity(0.05),
                            width: 2,
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(color: goldColor.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))
                          ] : [],
                        ),
                        child: Row(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    service['image_url'] ?? '',
                                    width: 70, height: 70, fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      width: 70, height: 70, color: Colors.grey[200],
                                      child: Icon(Icons.cut, color: Colors.grey[400]),
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Container(
                                    width: 70, height: 70,
                                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), borderRadius: BorderRadius.circular(10)),
                                    child: const Icon(Icons.check_circle, color: Colors.white, size: 30),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(service['name'] ?? '', style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Text(service['description'] ?? 'Layanan barbershop berkualitas', style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 8),
                                  Text("Rp ${service['price'] ?? '0'}", style: TextStyle(color: goldColor, fontWeight: FontWeight.bold, fontSize: 15)),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, color: onSurface.withOpacity(0.2), size: 14),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _selectedServiceData == null
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookingBarberScreen(
                            selectedService: _selectedServiceData!['name'].toString(),
                            price: "Rp ${_selectedServiceData!['price']}",
                          ),
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: goldColor,
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.grey[800],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('LANJUT PILIH BARBER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ),
      ],
    );
  }
}
