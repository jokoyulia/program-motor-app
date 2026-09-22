import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

const String baseUrl = "https://entangled-framing-reflex.ngrok-free.dev/api";

const Map<String, String> ngrokHeaders = {
  'Content-Type': 'application/json',
  'ngrok-skip-browser-warning': 'true',
};

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

  Map<String, dynamic>? orderToEdit;

  void _navigateToEditOrder(Map<String, dynamic> orderData) {
    setState(() {
      orderToEdit = orderData;
      _currentIndex = 0;
    });
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun sales?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                loggedKdSales = null;
                loggedNmSales = null;
                orderToEdit = null;
                _currentIndex = 0;
              });
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
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
        onLogout: _logout,
      ),
      DataOrderScreen(
        kdSales: loggedKdSales!,
        nmSales: loggedNmSales!,
        onEditOrder: _navigateToEditOrder,
        onLogout: _logout,
      ),
      BarangScreen(onLogout: _logout),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _logout();
      },
      child: Scaffold(
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
        headers: ngrokHeaders,
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
  final VoidCallback onLogout;

  const OrderScreen({
    super.key,
    required this.kdSales,
    required this.nmSales,
    this.editOrderData,
    required this.onEditComplete,
    required this.onLogout,
  });

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  String noOrder = 'Loading...';
  
  final _searchCustController = TextEditingController();
  List<dynamic> allCustomers = [];
  List<dynamic> custSearchResults = [];
  String? selectedKdCust;
  String? selectedNmCust;
  bool _isSearchingCust = false;

  final _searchBarangController = TextEditingController();
  List<dynamic> searchResults = [];
  bool _isSearching = false;
  
  List<Map<String, dynamic>> cart = [];
  bool isEditMode = false;
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
      selectedKdCust = data['kdCust'] ?? data['KdCust'];
      selectedNmCust = data['nmCust'] ?? data['NmCust'] ?? selectedKdCust;

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
      final res = await http.get(
        Uri.parse('$baseUrl/next-no-order'),
        headers: ngrokHeaders,
      );
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
      final res = await http.get(
        Uri.parse('$baseUrl/customer'),
        headers: ngrokHeaders,
      );
      if (res.statusCode == 200) {
        setState(() => allCustomers = jsonDecode(res.body));
      }
    } catch (e) {
      // Handle error
    }
  }

  void _searchCustomer(String q) {
    if (q.trim().isEmpty) {
      setState(() => custSearchResults.clear());
      return;
    }
    setState(() => _isSearchingCust = true);
    String query = q.toLowerCase();
    final results = allCustomers.where((c) {
      String kd = (c['kdCust'] ?? c['KdCust'] ?? '').toString().toLowerCase();
      String nm = (c['nmCust'] ?? c['NmCust'] ?? '').toString().toLowerCase();
      return kd.contains(query) || nm.contains(query);
    }).toList();

    setState(() {
      custSearchResults = results;
      _isSearchingCust = false;
    });
  }

  Future<void> _searchBarang(String q) async {
    if (q.trim().isEmpty) return;
    setState(() => _isSearching = true);
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/barang?cari=$q'),
        headers: ngrokHeaders,
      );
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
      selectedKdCust = null;
      selectedNmCust = null;
      _searchCustController.clear();
      custSearchResults.clear();
      searchResults.clear();
      _searchBarangController.clear();
    });
    widget.onEditComplete();
    _fetchNextNoOrder();
  }

  Future<void> _simpanOrder() async {
    if (selectedKdCust == null || selectedKdCust!.isEmpty) {
      _showMsg('Cari & pilih Customer terlebih dahulu!');
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
      "KdCust": selectedKdCust,
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
        headers: ngrokHeaders,
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
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: widget.onLogout,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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

                    if (selectedKdCust != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.person, color: Color(0xFF1E3A8A)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Customer Terpilih:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                  Text('$selectedNmCust ($selectedKdCust)',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.change_circle, color: Colors.orange),
                              tooltip: 'Ganti Customer',
                              onPressed: () => setState(() {
                                selectedKdCust = null;
                                selectedNmCust = null;
                              }),
                            )
                          ],
                        ),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchCustController,
                              decoration: const InputDecoration(
                                hintText: 'Cari Nama / Kode Customer...',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person_search),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              onChanged: _searchCustomer,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0A192F),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => _searchCustomer(_searchCustController.text),
                            child: _isSearchingCust
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Cari'),
                          ),
                        ],
                      ),
                      if (custSearchResults.isNotEmpty) ...[
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('PILIH CUSTOMER (Klik item):',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue)),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () => setState(() => custSearchResults.clear()),
                            )
                          ],
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: custSearchResults.length,
                          itemBuilder: (context, i) {
                            final c = custSearchResults[i];
                            String kd = c['kdCust'] ?? c['KdCust'] ?? '';
                            String nm = c['nmCust'] ?? c['NmCust'] ?? '';
                            String alm = c['alamat'] ?? c['Alamat'] ?? '';
                            return ListTile(
                              dense: true,
                              title: Text('$nm ($kd)', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(alm.isNotEmpty ? alm : 'Tanpa Alamat'),
                              trailing: const Icon(Icons.check_circle_outline, color: Colors.green),
                              onTap: () {
                                setState(() {
                                  selectedKdCust = kd;
                                  selectedNmCust = nm;
                                  custSearchResults.clear();
                                  _searchCustController.clear();
                                });
                              },
                            );
                          },
                        ),
                      ]
                    ]
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

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
                              prefixIcon: Icon(Icons.search),
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
// 3. SCREEN DAFTAR ORDER (FILTER SALES & BULAN)
// ==========================================
class DataOrderScreen extends StatefulWidget {
  final String kdSales;
  final String nmSales;
  final Function(Map<String, dynamic>) onEditOrder;
  final VoidCallback onLogout;

  const DataOrderScreen({
    super.key,
    required this.kdSales,
    required this.nmSales,
    required this.onEditOrder,
    required this.onLogout,
  });

  @override
  State<DataOrderScreen> createState() => _DataOrderScreenState();
}

class _DataOrderScreenState extends State<DataOrderScreen> {
  final _searchController = TextEditingController();
  List<dynamic> orders = [];
  bool isLoading = false;

  late String selectedBulan;
  final List<String> listBulan = [];

  @override
  void initState() {
    super.initState();
    _generateMonthList();
    _fetchOrders();
  }

  void _generateMonthList() {
    DateTime now = DateTime.now();
    for (int i = 0; i < 12; i++) {
      DateTime d = DateTime(now.year, now.month - i, 1);
      String monthStr = "${d.year}-${d.month.toString().padLeft(2, '0')}";
      listBulan.add(monthStr);
    }
    selectedBulan = listBulan.first;
  }

  Future<void> _fetchOrders([String search = '']) async {
    setState(() => isLoading = true);
    try {
      final url = '$baseUrl/orders-list?sales=${widget.kdSales}&bulan=$selectedBulan&cari=$search';
      final res = await http.get(Uri.parse(url), headers: ngrokHeaders);
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
        title: Text('Order Sales: ${widget.nmSales}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _fetchOrders(_searchController.text),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: widget.onLogout,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Row(
              children: [
                const Icon(Icons.calendar_month, color: Color(0xFF0A192F)),
                const SizedBox(width: 8),
                const Text('Pilih Bulan: ', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedBulan,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      border: OutlineInputBorder(),
                    ),
                    items: listBulan.map((b) {
                      return DropdownMenuItem(value: b, child: Text(b));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => selectedBulan = val);
                        _fetchOrders(_searchController.text);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari No Order / Customer...',
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
                    ? const Center(child: Text('Tidak ada data order pada bulan ini.'))
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
                                          OutlinedButton.icon(
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: const Color(0xFF1E3A8A),
                                            ),
                                            onPressed: () => _shareOrder(o),
                                            icon: const Icon(Icons.share, size: 16),
                                            label: const Text('Share Nota'),
                                          ),
                                          const SizedBox(width: 8),
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
// 4. SCREEN BARANG (SEARCH, MULTIPLE SELECT & PDF CETAK)
// ==========================================
class BarangScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const BarangScreen({super.key, required this.onLogout});

  @override
  State<BarangScreen> createState() => _BarangScreenState();
}

class _BarangScreenState extends State<BarangScreen> {
  final _searchController = TextEditingController();
  List<dynamic> allBarang = [];
  bool isLoading = false;

  // Set untuk menyimpan KodeBarang yang dicentang
  final Set<String> selectedKdBarang = {};

  @override
  void initState() {
    super.initState();
    _fetchBarang('');
  }

  Future<void> _fetchBarang(String q) async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/barang?cari=$q'),
        headers: ngrokHeaders,
      );
      if (res.statusCode == 200) {
        setState(() => allBarang = jsonDecode(res.body));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat barang: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _toggleSelectAll(bool? val) {
    setState(() {
      if (val == true) {
        for (var b in allBarang) {
          selectedKdBarang.add(b['kdBarang'] ?? b['KdBarang'] ?? '');
        }
      } else {
        selectedKdBarang.clear();
      }
    });
  }

  // CETAK PDF TERPISAH PER KELOMPOK BARANG
  Future<void> _generatePdf() async {
    if (selectedKdBarang.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih / Centang barang terlebih dahulu!')),
      );
      return;
    }

    // Filter barang yang dicentang
    List<dynamic> selectedItems = allBarang.where((b) {
      String kdBg = b['kdBarang'] ?? b['KdBarang'] ?? '';
      return selectedKdBarang.contains(kdBg);
    }).toList();

    // Kelompokkan barang berdasarkan NmKelompokBrg
    Map<String, List<dynamic>> grouped = {};
    for (var b in selectedItems) {
      String kel = b['nmKelompokBrg'] ?? b['NmKelompokBrg'] ?? 'LAIN-LAIN';
      if (!grouped.containsKey(kel)) {
        grouped[kel] = [];
      }
      grouped[kel]!.add(b);
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          List<pw.Widget> widgets = [];

          // Header Laporan
          widgets.add(
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text('LUCKY INDO MOTOR',
                      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Text('KATALOG DAFTAR BARANG SPAREPART',
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 16),
                ],
              ),
            ),
          );

          // Loop per kelompok barang
          grouped.forEach((kelompokName, items) {
            widgets.add(
              pw.Container(
                margin: const pw.EdgeInsets.only(top: 12, bottom: 6),
                padding: const pw.EdgeInsets.all(6),
                color: PdfColors.grey300,
                child: pw.Text('KELOMPOK BARANG: ${kelompokName.toUpperCase()}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
              ),
            );

            // Buat Tabel
            widgets.add(
              pw.Table.fromTextArray(
                headers: ['Kode Barang', 'Nama Barang', 'Stok', 'Harga Jual'],
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF0A192F)),
                cellHeight: 22,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.centerRight,
                },
                columnWidths: {
                  0: const pw.FixedColumnWidth(80),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FixedColumnWidth(50),
                  3: const pw.FixedColumnWidth(90),
                },
                data: items.map((b) {
                  String kdBg = b['kdBarang'] ?? b['KdBarang'] ?? '';
                  String nmBg = b['nmBarang'] ?? b['NmBarang'] ?? '';
                  double stok = double.tryParse((b['stok'] ?? b['Stok'] ?? 0).toString()) ?? 0;
                  double hrg = double.tryParse((b['hrgJual'] ?? b['HrgJual'] ?? 0).toString()) ?? 0;

                  return [
                    kdBg,
                    nmBg,
                    stok.toStringAsFixed(0),
                    'Rp ${hrg.toStringAsFixed(0)}',
                  ];
                }).toList(),
              ),
            );
          });

          return widgets;
        },
      ),
    );

    // Tampilkan Pratinjau / Print PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Katalog_Barang_Lucky_Indo_Motor.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isAllSelected = allBarang.isNotEmpty && selectedKdBarang.length == allBarang.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Barang'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Cetak PDF',
            onPressed: _generatePdf,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: widget.onLogout,
          ),
        ],
      ),
      body: Column(
        children: [
          // Pencarian Barang
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari Nama / Kode Barang...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _fetchBarang('');
                        },
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onSubmitted: (val) => _fetchBarang(val),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A192F),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _fetchBarang(_searchController.text),
                  child: const Text('Cari'),
                )
              ],
            ),
          ),

          // Header Centang Semua & Info Terpilih
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: isAllSelected,
                      onChanged: _toggleSelectAll,
                    ),
                    const Text('Pilih / Centang Semua', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                Text('${selectedKdBarang.length} Terpilih',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
              ],
            ),
          ),
          const Divider(height: 1),

          // List Barang
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : allBarang.isEmpty
                    ? const Center(child: Text('Barang tidak ditemukan.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: allBarang.length,
                        itemBuilder: (context, i) {
                          final item = allBarang[i];
                          String kdBg = item['kdBarang'] ?? item['KdBarang'] ?? '';
                          String nmBg = item['nmBarang'] ?? item['NmBarang'] ?? '';
                          String kelBg = item['nmKelompokBrg'] ?? item['NmKelompokBrg'] ?? 'LAIN-LAIN';
                          double hrg = double.tryParse((item['hrgJual'] ?? item['HrgJual'] ?? 0).toString()) ?? 0;
                          double stok = double.tryParse((item['stok'] ?? item['Stok'] ?? 0).toString()) ?? 0;

                          bool isChecked = selectedKdBarang.contains(kdBg);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: CheckboxListTile(
                              value: isChecked,
                              activeColor: const Color(0xFF0A192F),
                              onChanged: (bool? val) {
                                setState(() {
                                  if (val == true) {
                                    selectedKdBarang.add(kdBg);
                                  } else {
                                    selectedKdBarang.remove(kdBg);
                                  }
                                });
                              },
                              title: Text(nmBg, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Kode: $kdBg | Kelompok: $kelBg | Stok: ${stok.toStringAsFixed(0)}'),
                              secondary: Text(
                                'Rp ${hrg.toStringAsFixed(0)}',
                                style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold),
                              ),
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
