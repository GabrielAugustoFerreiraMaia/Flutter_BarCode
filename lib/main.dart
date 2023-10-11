import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Barcode Scanner',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      routes: {
        '/': (context) => HomePage(),
        '/addProduct': (context) {
          final String? barcode =
              ModalRoute.of(context)?.settings.arguments as String?;
          return AddProductPage(barcode: barcode!);
        },
        '/productList': (context) => ProductListPage(),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String barcode = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Barcode Scanner'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Scan Result: $barcode'),
            SizedBox(height: 20.0),
            RaisedButton(
              child: Text('Scan Barcode'),
              onPressed: _scanBarcode,
            ),
            SizedBox(height: 20.0),
            RaisedButton(
              child: Text('Add Product'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddProductPage(barcode: barcode),
                  ),
                );
              },
            ),
            RaisedButton(
              child: Text('Product List'),
              onPressed: () {
                Navigator.pushNamed(context, '/productList');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _scanBarcode() async {
    try {
      String barcode = await FlutterBarcodeScanner.scanBarcode(
        '#ff6666',
        'Cancel',
        true,
        ScanMode.BARCODE,
      );
      setState(() {
        this.barcode = barcode;
      });
    } catch (e) {
      print('Error: $e');
    }
  }
}

class AddProductPage extends StatefulWidget {
  final String barcode;

  AddProductPage({required this.barcode});

  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  TextEditingController barcodeController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  BuildContext? _pageContext;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      final routeArguments = ModalRoute.of(_pageContext!)?.settings.arguments;
      if (routeArguments != null && routeArguments is String) {
        String barcode = routeArguments;
        barcodeController.text = barcode;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Product'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: barcodeController,
              decoration: InputDecoration(
                labelText: 'Barcode',
              ),
            ),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Name',
              ),
            ),
            TextField(
              controller: priceController,
              decoration: InputDecoration(
                labelText: 'Price',
              ),
            ),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
              ),
            ),
            SizedBox(height: 20.0),
            RaisedButton(
              child: Text('Save'),
              onPressed: () {
                _saveProduct(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProduct(BuildContext context) async {
    String barcode = barcodeController.text;
    String name = nameController.text;
    String price = priceController.text;
    String description = descriptionController.text;

    // Open database
    Database database = await openDatabase(
      join(await getDatabasesPath(), 'products_database.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE IF NOT EXISTS products(id INTEGER PRIMARY KEY AUTOINCREMENT, barcode TEXT, name TEXT, price TEXT, description TEXT)',
        );
      },
      version: 1,
    );

    // Insert product data
    await database.insert(
      'products',
      {
        'barcode': barcode,
        'name': name,
        'price': price,
        'description': description,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Close database
    await database.close();

    // Navigate back to home page
    Navigator.pop(context);
  }
}

class ProductListPage extends StatefulWidget {
  @override
  _ProductListPageState createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  List<Map<String, dynamic>> products = [];

  @override
  void initState() {
    super.initState;
    _getProducts();
  }

  Future<void> _getProducts() async {
    Database database = await openDatabase(
      join(await getDatabasesPath(), 'products_database.db'),
    );
    List<Map<String, dynamic>> productList = await database.query('products');
    setState(() {
      products = productList;
    });
    await database.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Product List'),
      ),
      body: ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(products[index]['name']),
            subtitle: Text(products[index]['description']),
            trailing: Text(products[index]['price']),
          );
        },
      ),
    );
  }
}
