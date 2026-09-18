import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String baseUrl = "https://entangled-framing-reflex.ngrok-free.dev/api";

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lucky Indo Motor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF0A192F),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0A192F),
          primary: const Color(0xFF0A192F),
          secondary: const Color(0xFF1E3A8A),
        ),
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A192F),
          foregroundColor: Colors.white,
          elevation: 2,
        ),
      ),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  String? loggedKdSales;
  String? loggedNmSales;

  @override
  Widget build(BuildContext context) {
    if (loggedKdSales == null) {
      return LoginScreen(onLoginSuccess: (kd, nm) {
        setState(() {
          loggedKdSales = kd;
          loggedNmSales = nm;
        });
      });
    }

    final pages = [
      OrderScreen(kdSales: loggedKdSales!, nmSales: loggedNmSales!),
      const CustomerScreen(),
      const BarangScreen(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF0A192F),
        unselectedItemColor: Colors.grey,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart), label: 'Input Order'),
          BottomNavigationBarItem(
              icon: Icon(Icons.people), label: 'Data Customer'),
          BottomNavigationBarItem(
              icon: Icon(Icons.inventory), label: 'Data Barang'),
        ],
      ),
    );
  }
}

// ==========================================
// 1. SCREEN LOGIN SALES
// ==========================================
class LoginScreen extends StatefulWidget {
  final Function(String, String) onLoginSuccess;
  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _kdController = TextEditingController();
  final _pwdController = TextEditingController();
  bool _loading = false;

  Future<void> _login() async {
    if (_kdController.text.isEmpty || _pwdController.text.isEmpty) {
      _showMessage('Kode Sales dan Password wajib diisi');
      return;
    }

    setState(() => _loading = true);
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'kdSales': _kdController.text,
          'password': _pwdController.text,
          'KdSales': _kdController.text,
          'Password': _pwdController.text,
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        bool isSuccess = data['success'] == true ||
            data['status'] == 'success' ||
            data['success'] == 'true';

        if (isSuccess) {
          String salesKode = data['kdSales'] ??
              data['KdSales'] ??
              data['kd_sales'] ??
              _kdController.text;
          String salesNama =
              data['nmSales'] ?? data['NmSales'] ?? data['nm_sales'] ?? 'Sales';

          widget.onLoginSuccess(salesKode, salesNama);
        } else {
          _showMessage(data['message'] ?? 'Login Gagal');
        }
      } else {
        _showMessage('Login Gagal (Status HTTP: ${res.statusCode})');
      }
    } catch (e) {
      _showMessage('Error koneksi API: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A192F),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E3A8A),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.two_wheeler,
                        size: 48, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Aplikasi Penjualan Sparepart\nLucky Indo Motor',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A192F),
                    ),
                  ),
                  const Divider(height: 32),
                  TextField(
                    controller: _kdController,
                    decoration: InputDecoration(
                      labelText: 'Kode Sales',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _pwdController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _loading
                      ? const CircularProgressIndicator()
                      : SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0A192F),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: _login,
                            child: const Text('LOGIN',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 2. SCREEN INPUT & SIMPAN ORDER
// ==========================================
class OrderScreen extends StatefulWidget {
  final String kdSales;
  final String nmSales;
  const OrderScreen({super.key, required this.kdSales, required this.nmSales});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  String noOrder = 'Loading...';
  List<dynamic> customers = [];
  String? selectedCust;
  List<Map<String, dynamic>> cart = [];

  final _searchBarangController = TextEditingController();
  List<dynamic> searchResults = [];
  bool _isSearching = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchNextNoOrder();
    _loadCustomers();
  }

  // Mengambil NoOrder sekuesial otomatis dari API backend (Format: ORYYMMNNNN)
  Future<void> _fetchNextNoOrder() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/next-no-order'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          noOrder = data['noOrder'] ?? data['NoOrder'] ?? _fallbackNoOrder();
        });
      } else {
        setState(() => noOrder = _fallbackNoOrder());
      }
    } catch (e) {
      setState(() => noOrder = _fallbackNoOrder());
    }
  }

  String _fallbackNoOrder() {
    final now = DateTime.now();
    String yy = now.year.toString().substring(2);
    String mm = now.month.toString().padLeft(2, '0');
    return 'OR$yy${mm}0001';
  }

  Future<void> _loadCustomers() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/customer'));
      if (res.statusCode == 200) {
        setState(() => customers = jsonDecode(res.body));
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _searchBarang(String q) async {
    if (q.trim().isEmpty) return;
    setState(() => _isSearching = true);
    try {
      final res = await http.get(Uri.parse('$baseUrl/barang?cari=$q'));
      if (res.statusCode == 200) {
        setState(() => searchResults = jsonDecode(res.body));
      }
    } catch (e) {
      _showMsg('Gagal cari barang: $e');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  void _addBarangToCartDialog(Map<String, dynamic> barang) {
    final qtyController = TextEditingController(text: '1');
    double harga = double.tryParse((barang['hrgJual'] ?? barang['HrgJual'] ?? 0).toString()) ?? 0;
    double stokMaster = double.tryParse((barang['stok'] ?? barang['Stok'] ?? 0).toString()) ?? 0;
    String kdBg = barang['kdBarang'] ?? barang['KdBarang'] ?? '';
    String nmBg = barang['nmBarang'] ?? barang['NmBarang'] ?? '';

    // Hitung stok yang sudah ada di keranjang lokal
    double existingInCartQty = 0;
    int existingIdx = cart.indexWhere((item) => item['kdBarang'] == kdBg);
    if (existingIdx >= 0) {
      existingInCartQty = cart[existingIdx]['qty'];
    }
    double stokTersedia = stokMaster - existingInCartQty;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(nmBg),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Harga: Rp ${harga.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Stok Efektif Tersedia: ${stokTersedia.toStringAsFixed(0)}', 
                style: TextStyle(color: stokTersedia > 0 ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Jumlah Order (Qty)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A192F),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              double qtyInput = double.tryParse(qtyController.text) ?? 0;
              if (qtyInput <= 0) {
                _showMsg('Jumlah Qty tidak valid');
                return;
              }

              if (qtyInput > stokTersedia) {
                _showDialogWarning('Stok Tidak Mencukupi!', 
                    'Stok yang tersedia hanya ${stokTersedia.toStringAsFixed(0)}. Anda menginput ${qtyInput.toStringAsFixed(0)}.');
                return;
              }

              setState(() {
                if (existingIdx >= 0) {
                  cart[existingIdx]['qty'] += qtyInput;
                  cart[existingIdx]['subtotal'] = cart[existingIdx]['qty'] * harga;
                } else {
                  cart.add({
                    'kdBarang': kdBg,
                    'nmBarang': nmBg,
                    'harga': harga,
                    'qty': qtyInput,
                    'subtotal': qtyInput * harga,
                    'stokMaster': stokMaster,
                  });
                }

                // POIN 1: BERSIHKAN DAFTAR PENCARIAN SETELAH ITEM DIPILIH
                searchResults.clear();
                _searchBarangController.clear();
              });

              Navigator.pop(ctx);
              _showMsg('$nmBg ($qtyInput) ditambahkan ke keranjang');
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  void _showDialogWarning(String title, String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(msg),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  void _removeCartItem(int index) {
    setState(() {
      cart.removeAt(index);
    });
  }

  void _updateCartQty(int index, double delta) {
    double currentQty = cart[index]['qty'];
    double newQty = currentQty + delta;
    double stokMaster = cart[index]['stokMaster'] ?? 9999;

    if (newQty > stokMaster) {
      _showDialogWarning('Stok Terbatas', 'Jumlah order melebihi stok master (${stokMaster.toStringAsFixed(0)})');
      return;
    }

    setState(() {
      if (newQty <= 0) {
        cart.removeAt(index);
      } else {
        cart[index]['qty'] = newQty;
        cart[index]['subtotal'] = newQty * cart[index]['harga'];
      }
    });
  }

  double get _totalHarga {
    return cart.fold(0, (sum, item) => sum + (item['subtotal'] as double));
  }

  Future<void> _simpanOrder() async {
    if (selectedCust == null || selectedCust!.isEmpty) {
      _showMsg('Pilih Customer terlebih dahulu!');
      return;
    }
    if (cart.isEmpty) {
      _showMsg('Keranjang order masih kosong!');
      return;
    }

    setState(() => _isSaving = true);

    // POIN 3: MEMASTIKAN KODE CUSTOMER DISIMPAN DENGAN BENAR (KdCust)
    final payload = {
      "NoOrder": noOrder,
      "TglOrder": DateTime.now().toIso8601String(),
      "Sales": widget.kdSales,
      "KdCust": selectedCust, 
      "Total": _totalHarga,
      "Status": "BARU",
      "Items": cart.map((item) => {
        "NoOrder": noOrder,
        "KdBarang": item['kdBarang'],
        "NmBarang": item['nmBarang'],
        "Harga": item['harga'],
        "Qty": item['qty'],
        "Subtotal": item['subtotal']
      }).toList(),
    };

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/order'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      final resData = jsonDecode(res.body);
      
      if (res.statusCode == 200 && (resData['success'] == true || resData['status'] == 'success')) {
        _showMsg('Order $noOrder Berhasil Disimpan!');
        setState(() {
          cart.clear();
          selectedCust = null;
          searchResults.clear();
          _searchBarangController.clear();
        });
        // POIN 2: Minta NoOrder terbaru untuk order selanjutnya
        _fetchNextNoOrder();
      } else {
        // POIN 4: MENAMPILKAN WARNING JIKA STOK DI SERVER TIDAK CUKUP
        _showDialogWarning('Gagal Simpan Order', resData['message'] ?? 'Stok tidak mencukupi atau terjadi kesalahan.');
      }
    } catch (e) {
      _showMsg('Error koneksi simpan order: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Input Order Sales', style: TextStyle(fontSize: 16)),
            Text('Sales: ${widget.nmSales} (${widget.kdSales})',
                style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info NoOrder & Customer
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('No. Order:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3A8A),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            noOrder,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedCust,
                      decoration: const InputDecoration(
                        labelText: 'Pilih Customer',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: customers.map((c) {
                        String kd = c['kdCust'] ?? c['KdCust'] ?? '';
                        String nm = c['nmCust'] ?? c['NmCust'] ?? '';
                        return DropdownMenuItem<String>(
                          value: kd,
                          child: Text('$nm ($kd)'),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => selectedCust = val),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Cari Barang Section
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchBarangController,
                            decoration: const InputDecoration(
                              hintText: 'Cari Nama / Kode Barang...',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            onSubmitted: _searchBarang,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0A192F),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () =>
                              _searchBarang(_searchBarangController.text),
                          icon: _isSearching
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.search),
                          label: const Text('Cari'),
                        ),
                      ],
                    ),
                    // Hasil pencarian barang
                    if (searchResults.isNotEmpty) ...[
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('PILIH BARANG (Klik item):',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue)),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => setState(() => searchResults.clear()),
                          )
                        ],
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: searchResults.length,
                        itemBuilder: (context, i) {
                          final b = searchResults[i];
                          double hrg = double.tryParse((b['hrgJual'] ?? b['HrgJual'] ?? 0).toString()) ?? 0;
                          return ListTile(
                            dense: true,
                            title: Text(b['nmBarang'] ?? b['NmBarang'] ?? '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text(
                                'Kode: ${b['kdBarang'] ?? b['KdBarang']} | Stok Master: ${b['stok'] ?? b['Stok']}'),
                            trailing: Text('Rp ${hrg.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    color: Color(0xFF1E3A8A),
                                    fontWeight: FontWeight.bold)),
                            onTap: () => _addBarangToCartDialog(b),
                          );
                        },
                      ),
                    ]
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Item Order / Keranjang Section (POIN 5: Menampilkan Harga, Qty, Subtotal & Estimasi Total)
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Daftar Item Order:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('${cart.length} Jenis Item',
                            style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                    const Divider(),
                    cart.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                'Keranjang masih kosong.\nKetik & cari nama barang di atas.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: cart.length,
                            separatorBuilder: (ctx, i) => const Divider(),
                            itemBuilder: (ctx, i) {
                              final item = cart[i];
                              return Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(item['nmBarang'],
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        Text(
                                            'Harga: Rp ${item['harga'].toStringAsFixed(0)} x ${item['qty'].toStringAsFixed(0)}'),
                                        Text(
                                            'Subtotal: Rp ${item['subtotal'].toStringAsFixed(0)}',
                                            style: const TextStyle(
                                                color: Color(0xFF1E3A8A),
                                                fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                            Icons.remove_circle_outline,
                                            color: Colors.red),
                                        onPressed: () => _updateCartQty(i, -1),
                                      ),
                                      Text('${item['qty'].toStringAsFixed(0)}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      IconButton(
                                        icon: const Icon(
                                            Icons.add_circle_outline,
                                            color: Colors.green),
                                        onPressed: () => _updateCartQty(i, 1),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.grey),
                                        onPressed: () => _removeCartItem(i),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                    const Divider(height: 24),
                    // ESTIMASI TOTAL ORDER LIVE
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blueGrey.shade100),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('ESTIMASI TOTAL:',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold)),
                          Text(
                            'Rp ${_totalHarga.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _isSaving
                        ? const Center(child: CircularProgressIndicator())
                        : SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0A192F),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: _simpanOrder,
                              icon: const Icon(Icons.save),
                              label: const Text('SIMPAN ORDER',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
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
}

// ==========================================
// 3. SCREEN LIST CUSTOMER
// ==========================================
class CustomerScreen extends StatelessWidget {
  const CustomerScreen({super.key});

  Future<List<dynamic>> _getCustomers() async {
    final res = await http.get(Uri.parse('$baseUrl/customer'));
    return jsonDecode(res.body);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Customer')),
      body: FutureBuilder<List<dynamic>>(
        future: _getCustomers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, i) {
              final item = snapshot.data![i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    child: Text(item['kdCust'] ?? item['KdCust'] ?? ''),
                  ),
                  title: Text(item['nmCust'] ?? item['NmCust'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(item['alamat'] ?? item['Alamat'] ?? '-'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ==========================================
// 4. SCREEN LIST BARANG
// ==========================================
class BarangScreen extends StatelessWidget {
  const BarangScreen({super.key});

  Future<List<dynamic>> _getBarang() async {
    final res = await http.get(Uri.parse('$baseUrl/barang?cari='));
    return jsonDecode(res.body);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Barang')),
      body: FutureBuilder<List<dynamic>>(
        future: _getBarang(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, i) {
              final item = snapshot.data![i];
              double hrg = double.tryParse(
                      (item['hrgJual'] ?? item['HrgJual'] ?? 0).toString()) ??
                  0;
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.build, color: Color(0xFF0A192F)),
                  title: Text(item['nmBarang'] ?? item['NmBarang'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Stok: ${item['stok'] ?? item['Stok']}'),
                  trailing: Text(
                    'Rp ${hrg.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
