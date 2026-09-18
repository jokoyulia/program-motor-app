import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';

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

  // Data untuk passing jika melakukan edit order
  Map<String, dynamic>? orderToEdit;

  void _navigateToEditOrder(Map<String, dynamic> orderData) {
    setState(() {
      orderToEdit = orderData;
      _currentIndex = 0; // Pindah ke tab Input Order
    });
  }

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
      OrderScreen(
        kdSales: loggedKdSales!,
        nmSales: loggedNmSales!,
        editOrderData: orderToEdit,
        onEditComplete: () => setState(() => orderToEdit = null),
      ),
      DataOrderScreen(onEditOrder: _navigateToEditOrder),
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
              icon: Icon(Icons.receipt_long), label: 'Data Order'),
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
// 2. SCREEN INPUT & SIMPAN/EDIT ORDER
// ==========================================
class OrderScreen extends StatefulWidget {
  final String kdSales;
  final String nmSales;
  final Map<String, dynamic>? editOrderData;
  final VoidCallback onEditComplete;

  const OrderScreen({
    super.key,
    required this.kdSales,
    required this.nmSales,
    this.editOrderData,
    required this.onEditComplete,
  });

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  String noOrder = 'Loading...';
  List<dynamic> customers = [];
  String? selectedCust;
  List<Map<String, dynamic>> cart = [];
  bool isEditMode = false;

  final _searchBarangController = TextEditingController();
  List<dynamic> searchResults = [];
  bool _isSearching = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCustomers().then((_) {
      if (widget.editOrderData != null) {
        _populateEditData(widget.editOrderData!);
      } else {
        _fetchNextNoOrder();
      }
    });
  }

  @override
  void didUpdateWidget(covariant OrderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.editOrderData != null && widget.editOrderData != oldWidget.editOrderData) {
      _populateEditData(widget.editOrderData!);
    }
  }

  void _populateEditData(Map<String, dynamic> data) {
    setState(() {
      isEditMode = true;
      noOrder = data['noOrder'] ?? data['NoOrder'] ?? '';
      selectedCust = data['kdCust'] ?? data['KdCust'];

      cart.clear();
      List<dynamic> items = data['items'] ?? data['Items'] ?? [];
      for (var item in items) {
        double harga = double.tryParse((item['harga'] ?? item['Harga'] ?? 0).toString()) ?? 0;
        double qty = double.tryParse((item['qty'] ?? item['Qty'] ?? 0).toString()) ?? 0;
        cart.add({
          'kdBarang': item['kdBarang'] ?? item['KdBarang'],
          'nmBarang': item['nmBarang'] ?? item['NmBarang'],
          'harga': harga,
          'qty': qty,
          'subtotal': harga * qty,
          'stokMaster': 9999.0,
        });
      }
    });
  }

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

              if (qtyInput > stokTersedia && !isEditMode) {
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

  void _resetForm() {
    setState(() {
      isEditMode = false;
      cart.clear();
      selectedCust = null;
      searchResults.clear();
      _searchBarangController.clear();
    });
    widget.onEditComplete();
    _fetchNextNoOrder();
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

    final payload = {
      "NoOrder": noOrder,
      "TglOrder": DateTime.now().toIso8601String(),
      "Sales": widget.kdSales,
      "KdCust": selectedCust,
      "Total": _totalHarga,
      "Status": "BARU",
      "IsEdit": isEditMode,
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
        _showMsg(isEditMode ? 'Order $noOrder Berhasil Diperbarui!' : 'Order $noOrder Berhasil Disimpan!');
        _resetForm();
      } else {
        _showDialogWarning('Gagal Simpan Order', resData['message'] ?? 'Terjadi kesalahan pada server.');
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
            Text(isEditMode ? 'Edit Order ($noOrder)' : 'Input Order Sales', style: const TextStyle(fontSize: 16)),
            Text('Sales: ${widget.nmSales} (${widget.kdSales})',
                style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          if (isEditMode)
            IconButton(
              icon: const Icon(Icons.cancel),
              tooltip: 'Batal Edit',
              onPressed: _resetForm,
            )
        ],
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
                        const Text('No. Order:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isEditMode ? Colors.orange.shade800 : const Color(0xFF1E3A8A),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            noOrder,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                          onPressed: () => _searchBarang(_searchBarangController.text),
                          icon: _isSearching
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.search),
                          label: const Text('Cari'),
                        ),
                      ],
                    ),
                    if (searchResults.isNotEmpty) ...[
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('PILIH BARANG (Klik item):',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue)),
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
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(
                                'Kode: ${b['kdBarang'] ?? b['KdBarang']} | Stok Master: ${b['stok'] ?? b['Stok']}'),
                            trailing: Text('Rp ${hrg.toStringAsFixed(0)}',
                                style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
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

            // Item Order / Keranjang Section
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
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('${cart.length} Jenis Item', style: const TextStyle(color: Colors.grey)),
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
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item['nmBarang'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Text(
                                            'Harga: Rp ${item['harga'].toStringAsFixed(0)} x ${item['qty'].toStringAsFixed(0)}'),
                                        Text(
                                            'Subtotal: Rp ${item['subtotal'].toStringAsFixed(0)}',
                                            style: const TextStyle(
                                                color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                        onPressed: () => _updateCartQty(i, -1),
                                      ),
                                      Text('${item['qty'].toStringAsFixed(0)}',
                                          style: const TextStyle(fontWeight: FontWeight.bold)),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                                        onPressed: () => _updateCartQty(i, 1),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.grey),
                                        onPressed: () => _removeCartItem(i),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                    const Divider(height: 24),
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
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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
                                backgroundColor: isEditMode ? Colors.orange.shade800 : const Color(0xFF0A192F),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: _simpanOrder,
                              icon: Icon(isEditMode ? Icons.update : Icons.save),
                              label: Text(isEditMode ? 'UPDATE ORDER' : 'SIMPAN ORDER',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
// 3. SCREEN DAFTAR ORDER & DETAIL (REPLIES CUSTOMER)
// ==========================================
class DataOrderScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onEditOrder;
  const DataOrderScreen({super.key, required this.onEditOrder});

  @override
  State<DataOrderScreen> createState() => _DataOrderScreenState();
}

class _DataOrderScreenState extends State<DataOrderScreen> {
  final _searchController = TextEditingController();
  List<dynamic> orders = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders([String search = '']) async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(Uri.parse('$baseUrl/orders-list?cari=$search'));
      if (res.statusCode == 200) {
        setState(() => orders = jsonDecode(res.body));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data order: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _shareOrder(Map<String, dynamic> order) {
    String no = order['noOrder'] ?? order['NoOrder'] ?? '';
    String tgl = order['tglOrder'] ?? order['TglOrder'] ?? '';
    String cust = order['nmCust'] ?? order['NmCust'] ?? order['kdCust'] ?? '';
    String sales = order['nmSales'] ?? order['NmSales'] ?? order['sales'] ?? '';
    double total = double.tryParse((order['total'] ?? order['Total'] ?? 0).toString()) ?? 0;

    List<dynamic> items = order['items'] ?? order['Items'] ?? [];

    StringBuffer sb = StringBuffer();
    sb.writeln('===========================');
    sb.writeln('  LUCKY INDO MOTOR - NOTA ORDER');
    sb.writeln('===========================');
    sb.writeln('No. Order : $no');
    sb.writeln('Tanggal   : $tgl');
    sb.writeln('Customer  : $cust');
    sb.writeln('Sales     : $sales');
    sb.writeln('---------------------------');
    sb.writeln('DETAIL BARANG:');

    for (var item in items) {
      String nm = item['nmBarang'] ?? item['NmBarang'] ?? '';
      double hrg = double.tryParse((item['harga'] ?? item['Harga'] ?? 0).toString()) ?? 0;
      double qty = double.tryParse((item['qty'] ?? item['Qty'] ?? 0).toString()) ?? 0;
      double sub = double.tryParse((item['subtotal'] ?? item['Subtotal'] ?? 0).toString()) ?? 0;

      sb.writeln('- $nm');
      sb.writeln('  Rp ${hrg.toStringAsFixed(0)} x ${qty.toStringAsFixed(0)} = Rp ${sub.toStringAsFixed(0)}');
    }

    sb.writeln('---------------------------');
    sb.writeln('TOTAL : Rp ${total.toStringAsFixed(0)}');
    sb.writeln('===========================');
    sb.writeln('Terima kasih atas order Anda!');

    Share.share(sb.toString(), subject: 'Nota Order $no');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Order Transaksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _fetchOrders(_searchController.text),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari No Order / Customer / Sales...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _fetchOrders();
                  },
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onSubmitted: (val) => _fetchOrders(val),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : orders.isEmpty
                    ? const Center(child: Text('Belum ada data order.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: orders.length,
                        itemBuilder: (context, i) {
                          final o = orders[i];
                          String no = o['noOrder'] ?? o['NoOrder'] ?? '';
                          String status = o['status'] ?? o['Status'] ?? 'BARU';
                          String cust = o['nmCust'] ?? o['NmCust'] ?? o['kdCust'] ?? o['KdCust'] ?? '-';
                          double total = double.tryParse((o['total'] ?? o['Total'] ?? 0).toString()) ?? 0;
                          List<dynamic> items = o['items'] ?? o['Items'] ?? [];

                          bool isBaru = status.toUpperCase() == 'BARU';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 3,
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                backgroundColor: isBaru ? Colors.green : Colors.blueGrey,
                                child: const Icon(Icons.receipt, color: Colors.white, size: 20),
                              ),
                              title: Text('$no - $cust', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                  'Status: $status | Total: Rp ${total.toStringAsFixed(0)}',
                                  style: TextStyle(
                                      color: isBaru ? Colors.green.shade800 : Colors.black,
                                      fontWeight: FontWeight.w600)),
                              children: [
                                const Divider(height: 1),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  color: Colors.grey.shade50,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Sales: ${o['nmSales'] ?? o['Sales'] ?? '-'}',
                                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                      Text('Tanggal: ${o['tglOrder'] ?? o['TglOrder'] ?? '-'}',
                                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                      const SizedBox(height: 8),
                                      const Text('Detail Items:',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      const SizedBox(height: 4),
                                      ListView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: items.length,
                                        itemBuilder: (ctx, idx) {
                                          final item = items[idx];
                                          double hrg = double.tryParse((item['harga'] ?? item['Harga'] ?? 0).toString()) ?? 0;
                                          double qty = double.tryParse((item['qty'] ?? item['Qty'] ?? 0).toString()) ?? 0;
                                          double sub = double.tryParse((item['subtotal'] ?? item['Subtotal'] ?? 0).toString()) ?? 0;

                                          return Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 2),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    '${item['nmBarang'] ?? item['NmBarang']} (${qty.toStringAsFixed(0)}x)',
                                                    style: const TextStyle(fontSize: 12),
                                                  ),
                                                ),
                                                Text('Rp ${sub.toStringAsFixed(0)}',
                                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                      const Divider(height: 16),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          // Tombol Share
                                          OutlinedButton.icon(
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: const Color(0xFF1E3A8A),
                                            ),
                                            onPressed: () => _shareOrder(o),
                                            icon: const Icon(Icons.share, size: 16),
                                            label: const Text('Share Nota'),
                                          ),
                                          const SizedBox(width: 8),
                                          // Tombol Edit (Hanya jika status "BARU")
                                          if (isBaru)
                                            ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.orange.shade800,
                                                foregroundColor: Colors.white,
                                              ),
                                              onPressed: () => widget.onEditOrder(o),
                                              icon: const Icon(Icons.edit, size: 16),
                                              label: const Text('Edit Order'),
                                            ),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
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
              double hrg = double.tryParse((item['hrgJual'] ?? item['HrgJual'] ?? 0).toString()) ?? 0;
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.build, color: Color(0xFF0A192F)),
                  title: Text(item['nmBarang'] ?? item['NmBarang'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Stok: ${item['stok'] ?? item['Stok']}'),
                  trailing: Text(
                    'Rp ${hrg.toStringAsFixed(0)}',
                    style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold),
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
