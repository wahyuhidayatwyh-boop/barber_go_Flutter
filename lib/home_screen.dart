import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart'; 
import 'booking_service_screen.dart'; 
import 'login_screen.dart'; 
import 'booking_history_screen.dart';
import 'edit_profile_screen.dart';
import 'notification_service.dart';
import 'booking_success_screen.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _selectedCategory = 'Semua';
  String _searchQuery = '';

  // Data Profil Dinamis
  int? _userId;
  String _profileName = 'Pelanggan';
  String _profileEmail = '';
  String _profilePhone = '';
  String? _profileImage;

  // KONSTANTA BACKEND (WAJIB SESUAI REQUEST)
  static const String serverIp = '192.168.11.192';
  static const String baseUrl = 'http://192.168.11.192';

  // Data dari API
  List<dynamic> _services = [];
  List<dynamic> _allProducts = []; 
  List<dynamic> _banners = [];
  Map<String, dynamic>? _activeBooking; 
  bool _isLoadingData = true;

  // Data Status Barbershop Dinamis
  bool _isBarberOpen = false;
  int _totalQueue = 0;
  String _shopName = 'CUKURMEN Barbershop';
  String _shopAddress = 'Jl. Merdeka No. 123, Jakarta Pusat';

  final List<String> _categories = ['Semua', 'Pomade', 'Shampoo', 'Tonic', 'Beard Oil', 'Lainnya'];
  final Color goldColor = const Color(0xFFD4AF37);

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await _loadUserData();
    _fetchHomeData();
    _fetchActiveBooking(); 
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getInt('userId'); 
      _profileName = prefs.getString('userName') ?? 'Pelanggan';
      _profileEmail = prefs.getString('userEmail') ?? '';
      _profilePhone = prefs.getString('userPhone') ?? '-';
      _profileImage = prefs.getString('userImage');
    });
  }

  // PERBAIKAN LOGIC IMAGE URL
  String _fixImageUrl(String? url) {
    if (url == null || url.isEmpty || url == "null") {
      return 'https://i.pravatar.cc/150?u=$_profileName';
    }
    
    String fixedUrl = url;
    
    // Jika hanya nama file (misal: haircut_basic.jpg)
    if (!fixedUrl.startsWith('http')) {
      fixedUrl = '$baseUrl/storage/services/$fixedUrl';
    }

    if (fixedUrl.contains('localhost')) {
      fixedUrl = fixedUrl.replaceAll('localhost', serverIp);
    } else if (fixedUrl.contains('127.0.0.1')) {
      fixedUrl = fixedUrl.replaceAll('127.0.0.1', serverIp);
    }
    
    return fixedUrl;
  }

  Future<void> _fetchHomeData() async {
    const String apiUrl = '$baseUrl/api/home-data';
    try {
      final response = await http.get(Uri.parse(apiUrl)).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _services = data['services'] ?? [];
          _allProducts = data['products'] ?? [];
          _banners = data['banners'] ?? [];
          
          if (data['barber_status'] != null) {
            _isBarberOpen = data['barber_status']['is_open'] ?? false;
            _totalQueue = data['barber_status']['total_queue'] ?? 0;
            _shopName = data['barber_status']['shop_name'] ?? 'CUKURMEN Barbershop';
            _shopAddress = data['barber_status']['address'] ?? 'Jl. Merdeka No. 123, Jakarta Pusat';
          }
          
          _isLoadingData = false;
        });
      } else {
        setState(() => _isLoadingData = false);
      }
    } catch (e) {
      debugPrint('Error koneksi Beranda: $e');
      setState(() => _isLoadingData = false);
    }
  }

  Future<void> _fetchActiveBooking() async {
    if (_userId == null) return;
    final String apiUrl = '$baseUrl/api/active-booking?user_id=$_userId';
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        setState(() {
          _activeBooking = res['data'];
        });
      }
    } catch (e) {
      debugPrint("Error ambil booking aktif: $e");
    }
  }

  void _showLogoutConfirmation() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        title: const Text('Logout Akun', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context, 
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Ya, Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          currentName: _profileName,
          currentEmail: _profileEmail,
          currentPhone: _profilePhone,
        ),
      ),
    );

    // REFRESH DATA JIKA EDIT SUKSES
    if (result == true) {
      await _loadUserData();
    }
  }

  void _showProductDetail(dynamic product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.70,
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          children: [
            Container(margin: const EdgeInsets.only(top: 10), height: 4, width: 40, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(10))),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: Image.network(
                        _fixImageUrl(product['image_url']), 
                        fit: BoxFit.cover, 
                        errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image, size: 50))
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(product['price']?.toString() ?? '', style: TextStyle(color: goldColor, fontSize: 24, fontWeight: FontWeight.bold)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (product['is_available'] == 1 || product['is_available'] == true) ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1), 
                                  borderRadius: BorderRadius.circular(5)
                                ),
                                child: Text(
                                  (product['is_available'] == 1 || product['is_available'] == true) ? 'Tersedia' : 'Stok Habis', 
                                  style: TextStyle(color: (product['is_available'] == 1 || product['is_available'] == true) ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 12)
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          Text(product['name'] ?? '', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.bold)),
                          const Divider(height: 30),
                          const Text('Deskripsi Produk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 10),
                          Text(product['description'] ?? 'Tidak ada deskripsi produk.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 14, height: 1.5)),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildBerandaPage(), 
      const BookingServiceScreen(), 
      _buildProdukPage(), 
      _buildAkunPage()
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF121212) : const Color(0xFFFDFBF7),
      body: SafeArea(
        child: _isLoadingData 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
          : IndexedStack(index: _selectedIndex, children: pages),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBerandaPage() {
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    return RefreshIndicator(
      onRefresh: () async {
        await _fetchHomeData();
        await _fetchActiveBooking();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(onSurfaceColor, Theme.of(context).brightness == Brightness.dark),
            const SizedBox(height: 25),
            _buildQueueAndLocationCard(Theme.of(context).brightness == Brightness.dark, goldColor, Theme.of(context).colorScheme.surface, onSurfaceColor),
            const SizedBox(height: 25),
            if (_banners.isNotEmpty) _buildPromoBanner(_banners[0]), 
            const SizedBox(height: 25),
            Text('Layanan Kami', style: TextStyle(color: onSurfaceColor, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            _services.isEmpty 
              ? const Text('Belum ada layanan', style: TextStyle(color: Colors.grey))
              : SizedBox(
                  height: 130,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _services.length,
                    itemBuilder: (context, index) => _serviceIcon(_services[index], onSurfaceColor),
                  ),
                ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity, height: 55,
              child: ElevatedButton(
                onPressed: () => setState(() => _selectedIndex = 1),
                style: ElevatedButton.styleFrom(backgroundColor: goldColor, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('BOOKING SEKARANG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Produk Perawatan', style: TextStyle(color: onSurfaceColor, fontSize: 18, fontWeight: FontWeight.bold)),
                GestureDetector(onTap: () => setState(() => _selectedIndex = 2), child: Text('Lihat Semua', style: TextStyle(color: goldColor, fontSize: 12, fontWeight: FontWeight.bold))),
              ],
            ),
            const SizedBox(height: 15),
            _allProducts.isEmpty
              ? const Text('Belum ada produk', style: TextStyle(color: Colors.grey))
              : SizedBox(
                  height: 250,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _allProducts.length > 5 ? 5 : _allProducts.length,
                    itemBuilder: (context, index) => _buildProductCardPreview(_allProducts[index], onSurfaceColor),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildProdukPage() {
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final filteredProducts = _allProducts.where((p) {
      final matchesCategory = _selectedCategory == 'Semua' || (p['category']?.toString() ?? '') == _selectedCategory;
      final matchesSearch = (p['name']?.toString() ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return Column(
      children: [
        Container(
          width: double.infinity, padding: const EdgeInsets.all(16), color: surfaceColor,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Katalog Produk', style: TextStyle(color: onSurfaceColor, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Container(
              height: 45, decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.grey[100], borderRadius: BorderRadius.circular(8)),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                style: TextStyle(color: onSurfaceColor),
                decoration: InputDecoration(hintText: 'Cari produk...', prefixIcon: Icon(Icons.search, color: onSurfaceColor.withOpacity(0.5)), border: InputBorder.none, hintStyle: TextStyle(color: onSurfaceColor.withOpacity(0.4))),
              ),
            ),
          ]),
        ),
        Container(
          height: 50, width: double.infinity, color: surfaceColor,
          child: ListView.builder(
            scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), itemCount: _categories.length,
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final isSelected = _selectedCategory == cat;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
                child: Container(alignment: Alignment.center, margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8), padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: isSelected ? goldColor : Colors.transparent, borderRadius: BorderRadius.circular(20), border: Border.all(color: isSelected ? goldColor : onSurfaceColor.withOpacity(0.1))), child: Text(cat, style: TextStyle(color: isSelected ? Colors.black : onSurfaceColor.withOpacity(0.6), fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal))),
              );
            },
          ),
        ),
        Expanded(
          child: filteredProducts.isEmpty 
            ? Center(child: Text('Produk tidak ditemukan', style: TextStyle(color: onSurfaceColor.withOpacity(0.5)))) 
            : GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.62, mainAxisSpacing: 12, crossAxisSpacing: 12),
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) => _productCardGrid(filteredProducts[index], onSurfaceColor),
              ),
        ),
      ],
    );
  }

  Widget _buildAkunPage() {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            CircleAvatar(
              radius: 40, 
              backgroundColor: Colors.grey[300],
              backgroundImage: NetworkImage(_fixImageUrl(_profileImage)),
            ),
            const SizedBox(width: 20),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_profileName, style: TextStyle(color: onSurface, fontSize: 20, fontWeight: FontWeight.bold)),
              Text(_profileEmail, style: TextStyle(color: onSurface.withOpacity(0.5))),
              Text(_profilePhone, style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 13)),
            ])),
            IconButton(onPressed: _navigateToEditProfile, icon: Icon(Icons.edit_note, color: goldColor, size: 35)),
          ]),
          const SizedBox(height: 30),
          
          if (_activeBooking != null) _buildActiveBookingCard(onSurface),
          
          const SizedBox(height: 20),
          Text('Menu Akun', style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          ListTile(leading: Icon(Icons.history, color: goldColor), title: const Text('Riwayat Booking'), trailing: const Icon(Icons.arrow_forward_ios, size: 14), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BookingHistoryScreen()))),
          const Divider(color: Colors.white10),
          ListTile(leading: const Icon(Icons.logout, color: Colors.redAccent), title: const Text('Logout', style: TextStyle(color: Colors.redAccent)), onTap: _showLogoutConfirmation),
        ],
      ),
    );
  }

  Widget _buildActiveBookingCard(Color onSurface) {
    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: goldColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: goldColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Booking Aktif', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(5)),
                child: const Text('Menunggu', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Icon(Icons.cut, color: goldColor, size: 20),
              const SizedBox(width: 10),
              Text(_activeBooking!['service_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person, color: Colors.grey, size: 20),
              const SizedBox(width: 10),
              Text(_activeBooking!['barber_name'] ?? '', style: const TextStyle(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.grey, size: 20),
              const SizedBox(width: 10),
              Text("${_activeBooking!['booking_date']} | ${_activeBooking!['booking_time']}", style: const TextStyle(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BookingSuccessScreen(bookingData: _activeBooking!)),
                ).then((_) => _fetchActiveBooking());
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: goldColor),
                foregroundColor: goldColor
              ),
              child: const Text('LIHAT QR CODE'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color onSurface, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Halo, $_profileName! 👋', style: TextStyle(color: onSurface, fontSize: 22, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('Mau cukur apa hari ini?', style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 14)),
          ]),
        ),
        Row(children: [
          IconButton(onPressed: () => themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark, icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: goldColor)),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 18, 
            backgroundColor: Colors.grey[300],
            backgroundImage: NetworkImage(_fixImageUrl(_profileImage)),
          ),
        ])
      ],
    );
  }

  Widget _buildQueueAndLocationCard(bool isDark, Color gold, Color surface, Color onSurface) {
    return Container(
      padding: const EdgeInsets.all(20), 
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(15), border: Border.all(color: isDark ? Colors.white10 : gold.withOpacity(0.1))), 
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, 
            children: [
              Row(
                children: [
                  Icon(Icons.circle, color: _isBarberOpen ? Colors.green : Colors.red, size: 8), 
                  const SizedBox(width: 8), 
                  Text(_isBarberOpen ? 'Barbershop Buka' : 'Barbershop Tutup', style: TextStyle(color: _isBarberOpen ? Colors.green : Colors.red, fontWeight: FontWeight.w600))
                ]
              ), 
              Text('$_totalQueue Antrean', style: TextStyle(color: gold, fontWeight: FontWeight.bold))
            ]
          ), 
          Divider(color: onSurface.withOpacity(0.1), height: 30), 
          Row(
            children: [
              Icon(Icons.location_on, color: gold, size: 20), 
              const SizedBox(width: 10), 
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  children: [
                    Text(_shopName, style: TextStyle(color: onSurface, fontWeight: FontWeight.bold)), 
                    Text(_shopAddress, style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 12))
                  ]
                )
              )
            ]
          )
        ]
      )
    );
  }

  Widget _buildPromoBanner(dynamic banner) {
    return Container(
      height: 160, width: double.infinity,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), image: DecorationImage(image: NetworkImage(_fixImageUrl(banner['image_url'])), fit: BoxFit.cover)),
      child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), gradient: LinearGradient(colors: [Colors.black87, Colors.transparent], begin: Alignment.bottomLeft)), padding: const EdgeInsets.all(20), child: Column(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(banner['title'] ?? 'Promo', style: TextStyle(color: goldColor, fontWeight: FontWeight.bold, fontSize: 18)), Text(banner['description'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 12))])),
    );
  }

  Widget _serviceIcon(dynamic s, Color onSurface) {
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = 1),
      child: Padding(
        padding: const EdgeInsets.only(right: 15),
        child: Column(
          children: [
            Container(
              height: 70,
              width: 70,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: goldColor.withOpacity(0.3), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Image.network(
                  _fixImageUrl(s['image_url']),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => 
                      Icon(Icons.cut, color: goldColor, size: 30),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              s['name'] ?? '',
              style: TextStyle(
                color: onSurface, 
                fontSize: 12, 
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              "Rp ${s['price'] ?? '0'}",
              style: TextStyle(
                color: goldColor, 
                fontSize: 11, 
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _productCardGrid(dynamic p, Color onSurface) {
    bool isAvailable = p['is_available'] == 1 || p['is_available'] == true;
    return GestureDetector(
      onTap: () => _showProductDetail(p),
      child: Container(
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(10), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]), 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            AspectRatio(aspectRatio: 1, child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(10)), child: Image.network(_fixImageUrl(p['image_url']), fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image))))), 
            Padding(
              padding: const EdgeInsets.all(10.0), 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  Text(p['name'] ?? '', style: TextStyle(color: onSurface, fontSize: 13, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis), 
                  const SizedBox(height: 4), 
                  Text(p['price']?.toString() ?? '', style: TextStyle(color: goldColor, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: isAvailable ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Text(isAvailable ? 'Tersedia' : 'Habis', style: TextStyle(color: isAvailable ? Colors.green : Colors.red, fontSize: 10, fontWeight: FontWeight.bold)))
                ]
              )
            )
          ]
        )
      )
    );
  }

  Widget _buildProductCardPreview(dynamic p, Color onSurface) {
    bool isAvailable = p['is_available'] == 1 || p['is_available'] == true;
    return GestureDetector(
      onTap: () => _showProductDetail(p),
      child: Container(
        width: 150, 
        margin: const EdgeInsets.only(right: 12), 
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(10), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]), 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            AspectRatio(aspectRatio: 1, child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(10)), child: Image.network(_fixImageUrl(p['image_url']), fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image))))),
            Padding(
              padding: const EdgeInsets.all(8.0), 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  Text(p['name'] ?? '', style: TextStyle(color: onSurface, fontSize: 12, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis), 
                  Text(p['price']?.toString() ?? '', style: TextStyle(color: goldColor, fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(isAvailable ? 'Tersedia' : 'Habis', style: TextStyle(color: isAvailable ? Colors.green : Colors.red, fontSize: 9, fontWeight: FontWeight.bold))
                ]
              )
            )
          ]
        )
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex, 
      onTap: (index) {
        setState(() => _selectedIndex = index);
        if (index == 3) {
          _fetchActiveBooking();
        }
      }, 
      type: BottomNavigationBarType.fixed, 
      backgroundColor: Theme.of(context).colorScheme.surface, 
      selectedItemColor: goldColor, 
      unselectedItemColor: Colors.grey, 
      showUnselectedLabels: true, 
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Beranda'), 
        BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Booking'), 
        BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Produk'), 
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Akun')
      ]
    );
  }
}
