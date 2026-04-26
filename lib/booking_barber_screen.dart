import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'booking_datetime_screen.dart';

class BookingBarberScreen extends StatefulWidget {
  final String selectedService;
  final String price;

  const BookingBarberScreen({
    super.key, 
    required this.selectedService,
    required this.price,
  });

  @override
  State<BookingBarberScreen> createState() => _BookingBarberScreenState();
}

class _BookingBarberScreenState extends State<BookingBarberScreen> {
  String? _selectedBarber;
  final goldColor = const Color(0xFFD4AF37);
  
  List<dynamic> _barbers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBarbers();
  }

  Future<void> _fetchBarbers() async {
    // TAMBAHKAN PORT :8000 AGAR BISA KONEK KE LARAVEL
    const String apiUrl = 'http://192.168.11.192/api/barbers';
    try {
      final response = await http.get(Uri.parse(apiUrl)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _barbers = data['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Gagal terhubung ke API: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Pilih Barber', style: TextStyle(color: onSurface, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Siapa Barber Anda?',
                  style: TextStyle(color: onSurface, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Layanan: ${widget.selectedService}',
                  style: TextStyle(color: goldColor, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
              : _barbers.isEmpty
                ? const Center(child: Text('Barber tidak tersedia\nCek Server (php artisan serve)', textAlign: TextAlign.center))
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.8,
                      mainAxisSpacing: 15,
                      crossAxisSpacing: 15,
                    ),
                    itemCount: _barbers.length,
                    itemBuilder: (context, index) {
                      final barber = _barbers[index];
                      final isSelected = _selectedBarber == barber['name'];

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedBarber = barber['name'];
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: isSelected ? goldColor : Colors.white.withOpacity(0.05),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundImage: NetworkImage(barber['image_url'] ?? 'https://i.pravatar.cc/150'),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                barber['name'] ?? '',
                                style: TextStyle(color: onSurface, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                barber['experience'] ?? '',
                                style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 12),
                              ),
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
                onPressed: _selectedBarber == null ? null : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookingDatetimeScreen(
                        selectedService: widget.selectedService,
                        selectedBarber: _selectedBarber!,
                        price: widget.price,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: goldColor, foregroundColor: Colors.black),
                child: const Text('LANJUT PILIH WAKTU', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
