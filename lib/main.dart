import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Target API Anda
const String baseUrl = "https://desktop-5oa4fls.tail5c9674.ts.net/api";

void main() {
  runApp(const MaterialApp(
    home: MainNavigation(),
    debugShowCheckedModeBanner: false,
  ));
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
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart), label: 'Order'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Customer'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Barang'),
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

        // Membaca key respons secara fleksibel
        bool isSuccess = data['success'] == true ||
            data['status'] == 'success' ||
            data['success'] == 'true';

        if (isSuccess || res.statusCode == 200) {
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
      appBar: AppBar(title: const Text('Login Sales')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
                controller: _kdController,
                decoration: const InputDecoration(labelText: 'Kode Sales')),
            TextField(
                controller: _pwdController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password')),
            const SizedBox(height: 20),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(onPressed: _login, child: const Text('LOGIN')),
          ],
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
  List<dynamic> customers = [];
  String? selectedCust;
  List<Map<String, dynamic>> cart = [];

  final _searchBarangController = TextEditingController();
  List<dynamic> searchResults = [];

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/customer'));
      if (res.statusCode == 200) {
        setState(() => customers = jsonDecode(res.body));
      }
    } catch (e) {
      // handle error
    }
  }

  Future<void> _searchBarang(String q) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/barang?cari=$q'));
      if (res.statusCode == 200) {
        setState(() => searchResults = jsonDecode(res.body));
      }
    } catch (e) {
      // handle error
    }
  }

  Future<void> _simpanOrder() async {
    if (selectedCust == null || cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih Customer & minimal 1 item barang')),
      );
      return;
    }

    final payload = {
      "Sales": widget.kdSales,
      "KdCust": selectedCust,
      "Items": cart
          .map((item) => {"KdBarang": item['kdBarang'], "Qty": item['qty']})
          .toList(),
    };

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/order'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      final resData = jsonDecode(res.body);
      if (resData['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order Berhasil! No: ${resData['noOrder']}')),
        );
        setState(() => cart.clear());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: ${resData['message']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Order - ${widget.nmSales}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              hint: const Text('Pilih Customer'),
              items: customers.map((c) {
                return DropdownMenuItem<String>(
                  value: c['kdCust'] ?? c['KdCust'],
                  child: Text('${c['nmCust'] ?? c['NmCust']} (${c['kdCust'] ?? c['KdCust']})'),
                );
              }).toList(),
              onChanged: (val) => setState(() => selectedCust = val),
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchBarangController,
                    decoration: const InputDecoration(
                        hintText: 'Cari barang (e.g. tromol)'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _searchBarang(_searchBarangController.text),
                ),
              ],
            ),
            ...searchResults.map((b) => ListTile(
                  title: Text(b['nmBarang'] ?? b['NmBarang'] ?? ''),
                  subtitle: Text('Rp ${b['hrgJual'] ?? b['HrgJual']} | Stok: ${b['stok'] ?? b['Stok']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_shopping_cart),
                    onPressed: () {
                      setState(() {
                        cart.add({
                          'kdBarang': b['kdBarang'] ?? b['KdBarang'],
                          'nmBarang': b['nmBarang'] ?? b['NmBarang'],
                          'qty': 1.0,
                          'harga': b['hrgJual'] ?? b['HrgJual']
                        });
                      });
                    },
                  ),
                )),
            const Divider(),
            const Text('Keranjang:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            ...cart.map((item) => ListTile(
                  title: Text(item['nmBarang']),
                  subtitle: Text('Qty: ${item['qty']} x ${item['harga']}'),
                )),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(45)),
              onPressed: _simpanOrder,
              child: const Text('SIMPAN ORDER'),
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
            itemCount: snapshot.data!.length,
            itemBuilder: (context, i) {
              final item = snapshot.data![i];
              return ListTile(
                title: Text(item['nmCust'] ?? item['NmCust'] ?? ''),
                subtitle: Text(item['alamat'] ?? item['Alamat'] ?? ''),
                leading: CircleAvatar(child: Text(item['kdCust'] ?? item['KdCust'] ?? '')),
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
            itemCount: snapshot.data!.length,
            itemBuilder: (context, i) {
              final item = snapshot.data![i];
              return ListTile(
                title: Text(item['nmBarang'] ?? item['NmBarang'] ?? ''),
                subtitle: Text('Stok: ${item['stok'] ?? item['Stok']}'),
                trailing: Text('Rp ${item['hrgJual'] ?? item['HrgJual']}'),
              );
            },
          );
        },
      ),
    );
  }
}
