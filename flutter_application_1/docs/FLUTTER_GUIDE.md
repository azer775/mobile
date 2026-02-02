# Flutter Learning Guide

A comprehensive guide for your first Flutter project covering widgets, routing, and CRUD operations.

---

## Table of Contents

1. [Stateless vs Stateful Widgets](#1-stateless-vs-stateful-widgets)
2. [Creating Widgets](#2-creating-widgets)
3. [Routing & Navigation](#3-routing--navigation)
4. [CRUD Operations Guide](#4-crud-operations-guide)
5. [Project Structure](#5-project-structure)

---

## 1. Stateless vs Stateful Widgets

### StatelessWidget

A widget that **never changes** after being built. It's immutable.

**When to use:**
- Static content (labels, icons, images)
- Widgets that only depend on constructor parameters
- Display-only components

```dart
class WelcomeMessage extends StatelessWidget {
  final String username;  // All properties must be final

  const WelcomeMessage({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Text('Welcome, $username!');
  }
}

// Usage
WelcomeMessage(username: 'John')
```

### StatefulWidget

A widget that **can change** over time. It has mutable state.

**When to use:**
- Forms and text inputs
- Counters, toggles, checkboxes
- Data fetching (loading → success → error)
- Animations
- Anything interactive

```dart
class Counter extends StatefulWidget {
  const Counter({super.key});

  @override
  State<Counter> createState() => _CounterState();
}

class _CounterState extends State<Counter> {
  int _count = 0;  // Mutable state

  void _increment() {
    setState(() {  // Tell Flutter to rebuild
      _count++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Count: $_count'),
        ElevatedButton(
          onPressed: _increment,
          child: Text('Add'),
        ),
      ],
    );
  }
}
```

### Lifecycle Methods (StatefulWidget only)

```dart
class _MyWidgetState extends State<MyWidget> {
  @override
  void initState() {
    super.initState();
    // Called ONCE when widget is created
    // Initialize controllers, start listeners, fetch data
  }

  @override
  void didUpdateWidget(MyWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Called when parent rebuilds with new parameters
  }

  @override
  void dispose() {
    // Called when widget is removed
    // Clean up: dispose controllers, cancel subscriptions
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
```

---

## 2. Creating Widgets

### Step 1: Decide Stateless or Stateful

Ask yourself: "Does this widget need to change after it's built?"
- **No** → StatelessWidget
- **Yes** → StatefulWidget

### Step 2: Create the Widget

**Stateless Template:**
```dart
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  // 1. Declare final properties
  final String title;
  final VoidCallback? onTap;

  // 2. Create const constructor
  const MyWidget({
    super.key,
    required this.title,
    this.onTap,
  });

  // 3. Implement build method
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(title),
    );
  }
}
```

**Stateful Template:**
```dart
import 'package:flutter/material.dart';

class MyWidget extends StatefulWidget {
  // Properties from parent
  final String initialValue;

  const MyWidget({super.key, required this.initialValue});

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  // Mutable state variables
  late String _value;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;  // Access widget properties via 'widget.'
  }

  @override
  void dispose() {
    _controller.dispose();  // Always clean up controllers!
    super.dispose();
  }

  void _updateValue(String newValue) {
    setState(() {
      _value = newValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(_value);
  }
}
```

### Step 3: Use the Widget

```dart
// In another widget's build method:
Column(
  children: [
    MyWidget(title: 'Hello'),
    MyWidget(
      title: 'Click me',
      onTap: () => print('Tapped!'),
    ),
  ],
)
```

---

## 3. Routing & Navigation

### Basic Navigation

```dart
// Push new screen (adds to stack)
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => DetailScreen()),
);

// Pop current screen (go back)
Navigator.pop(context);

// Pop and return data
Navigator.pop(context, 'result data');

// Push and wait for result
final result = await Navigator.push<String>(
  context,
  MaterialPageRoute(builder: (context) => SelectionScreen()),
);
```

### Named Routes

**1. Define routes in `app_routes.dart`:**
```dart
class AppRoutes {
  static const String home = '/';
  static const String users = '/users';
  static const String userDetail = '/user-detail';

  static Map<String, WidgetBuilder> get routes {
    return {
      home: (context) => const HomePage(),
      users: (context) => const UsersPage(),
    };
  }
}
```

**2. Configure in `main.dart`:**
```dart
MaterialApp(
  initialRoute: AppRoutes.home,
  routes: AppRoutes.routes,
  onGenerateRoute: AppRoutes.onGenerateRoute,
  onUnknownRoute: AppRoutes.onUnknownRoute,
)
```

**3. Navigate using route names:**
```dart
// Simple navigation
Navigator.pushNamed(context, '/users');

// With arguments
Navigator.pushNamed(
  context, 
  '/user-detail',
  arguments: {'userId': 123},
);

// Replace current screen
Navigator.pushReplacementNamed(context, '/home');

// Clear stack and go to route
Navigator.pushNamedAndRemoveUntil(
  context, 
  '/home', 
  (route) => false,
);
```

---

## 4. CRUD Operations Guide

This section shows you how to create complete CRUD (Create, Read, Update, Delete) operations for any entity.

### Step 1: Create the Entity (Database Model)

📁 `lib/data/models/entities/product_entity.dart`

```dart
import '../base/base_entity.dart';

class ProductEntity extends BaseEntity {
  String name;
  String description;
  double price;
  int quantity;

  ProductEntity({
    super.id,
    required this.name,
    required this.description,
    required this.price,
    required this.quantity,
    super.createdAt,
    super.updatedAt,
  });

  @override
  String get tableName => 'products';

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'quantity': quantity,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory ProductEntity.fromMap(Map<String, dynamic> map) {
    return ProductEntity(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String,
      price: (map['price'] as num).toDouble(),
      quantity: map['quantity'] as int,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }
}
```

### Step 2: Create the DTO (API Model)

📁 `lib/data/models/dtos/product_dto.dart`

```dart
import '../base/base_dto.dart';
import '../entities/product_entity.dart';

class ProductDto extends BaseDto {
  final int? id;
  final String name;
  final String description;
  final double price;
  final int quantity;

  ProductDto({
    this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.quantity,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'quantity': quantity,
    };
  }

  factory ProductDto.fromJson(Map<String, dynamic> json) {
    return ProductDto(
      id: json['id'] as int?,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] as int,
    );
  }

  // Convert DTO to Entity
  ProductEntity toEntity() {
    return ProductEntity(
      id: id,
      name: name,
      description: description,
      price: price,
      quantity: quantity,
    );
  }

  // Create DTO from Entity
  factory ProductDto.fromEntity(ProductEntity entity) {
    return ProductDto(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      price: entity.price,
      quantity: entity.quantity,
    );
  }
}
```

### Step 3: Add Database Table

📁 `lib/data/datasources/local/database_helper.dart`

Add to `_onCreate` method:

```dart
Future<void> _onCreate(Database db, int version) async {
  // Existing tables...
  
  // Add products table
  await db.execute('''
    CREATE TABLE products (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      description TEXT,
      price REAL NOT NULL,
      quantity INTEGER NOT NULL DEFAULT 0,
      created_at TEXT,
      updated_at TEXT
    )
  ''');
}
```

### Step 4: Create Local Datasource (Database Operations)

📁 `lib/data/datasources/local/product_local_datasource.dart`

```dart
import '../../models/entities/product_entity.dart';
import 'database_helper.dart';

class ProductLocalDatasource {
  final DatabaseHelper _databaseHelper;

  ProductLocalDatasource({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  // CREATE
  Future<int> insertProduct(ProductEntity product) async {
    final data = product.toMap();
    data['created_at'] = DateTime.now().toIso8601String();
    data['updated_at'] = DateTime.now().toIso8601String();
    return await _databaseHelper.insert('products', data);
  }

  // READ - All
  Future<List<ProductEntity>> getAllProducts() async {
    final results = await _databaseHelper.query('products', orderBy: 'id DESC');
    return results.map((map) => ProductEntity.fromMap(map)).toList();
  }

  // READ - By ID
  Future<ProductEntity?> getProductById(int id) async {
    final results = await _databaseHelper.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isNotEmpty) {
      return ProductEntity.fromMap(results.first);
    }
    return null;
  }

  // UPDATE
  Future<int> updateProduct(ProductEntity product) async {
    final data = product.toMap();
    data['updated_at'] = DateTime.now().toIso8601String();
    return await _databaseHelper.update(
      'products',
      data,
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  // DELETE
  Future<int> deleteProduct(int id) async {
    return await _databaseHelper.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // SEARCH
  Future<List<ProductEntity>> searchProducts(String query) async {
    final results = await _databaseHelper.query(
      'products',
      where: 'name LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );
    return results.map((map) => ProductEntity.fromMap(map)).toList();
  }
}
```

### Step 5: Create Remote Datasource (API Operations)

📁 `lib/data/datasources/remote/product_remote_datasource.dart`

```dart
import '../../models/dtos/product_dto.dart';
import 'api_client.dart';

class ProductRemoteDatasource {
  final ApiClient _apiClient;

  ProductRemoteDatasource({required ApiClient apiClient})
      : _apiClient = apiClient;

  // CREATE
  Future<ProductDto> createProduct(ProductDto product) async {
    final response = await _apiClient.post('/products', body: product.toJson());
    return ProductDto.fromJson(response);
  }

  // READ - All
  Future<List<ProductDto>> getProducts() async {
    final response = await _apiClient.get('/products');
    final List<dynamic> data = response as List<dynamic>;
    return data.map((json) => ProductDto.fromJson(json)).toList();
  }

  // READ - By ID
  Future<ProductDto> getProductById(int id) async {
    final response = await _apiClient.get('/products/$id');
    return ProductDto.fromJson(response);
  }

  // UPDATE
  Future<ProductDto> updateProduct(int id, ProductDto product) async {
    final response = await _apiClient.put('/products/$id', body: product.toJson());
    return ProductDto.fromJson(response);
  }

  // DELETE
  Future<void> deleteProduct(int id) async {
    await _apiClient.delete('/products/$id');
  }
}
```

### Step 6: Create the Form

📁 `lib/presentation/forms/product_form.dart`

```dart
import 'package:flutter/material.dart';
import '../../core/utils/validators.dart';
import '../../data/models/entities/product_entity.dart';

class ProductForm extends StatefulWidget {
  final ProductEntity? product;  // null = create, filled = edit
  final Function(ProductEntity) onSave;

  const ProductForm({
    super.key,
    this.product,
    required this.onSave,
  });

  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _quantityController;
  bool _isLoading = false;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _descriptionController = TextEditingController(text: widget.product?.description ?? '');
    _priceController = TextEditingController(text: widget.product?.price.toString() ?? '');
    _quantityController = TextEditingController(text: widget.product?.quantity.toString() ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final product = ProductEntity(
        id: widget.product?.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        quantity: int.parse(_quantityController.text.trim()),
        createdAt: widget.product?.createdAt,
        updatedAt: DateTime.now(),
      );

      widget.onSave(product);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Product' : 'Add Product'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => Validators.required(v, fieldName: 'Name'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (v) => Validators.required(v, fieldName: 'Price'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
                validator: (v) => Validators.required(v, fieldName: 'Quantity'),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _onSubmit,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : Text(_isEditing ? 'Update' : 'Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### Step 7: Create the List Page

📁 `lib/presentation/pages/products_page.dart`

```dart
import 'package:flutter/material.dart';
import '../../data/datasources/local/product_local_datasource.dart';
import '../../data/models/entities/product_entity.dart';
import '../forms/product_form.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final ProductLocalDatasource _datasource = ProductLocalDatasource();
  List<ProductEntity> _products = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  // READ - Load all products
  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await _datasource.getAllProducts();
      setState(() => _products = products);
    } catch (e) {
      _showError('Error loading products: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // CREATE
  Future<void> _createProduct(ProductEntity product) async {
    try {
      await _datasource.insertProduct(product);
      _showSuccess('Product created!');
      _loadProducts();
    } catch (e) {
      _showError('Error creating product: $e');
    }
  }

  // UPDATE
  Future<void> _updateProduct(ProductEntity product) async {
    try {
      await _datasource.updateProduct(product);
      _showSuccess('Product updated!');
      _loadProducts();
    } catch (e) {
      _showError('Error updating product: $e');
    }
  }

  // DELETE
  Future<void> _deleteProduct(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _datasource.deleteProduct(id);
        _showSuccess('Product deleted!');
        _loadProducts();
      } catch (e) {
        _showError('Error deleting product: $e');
      }
    }
  }

  void _navigateToForm({ProductEntity? product}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductForm(
          product: product,
          onSave: (p) {
            Navigator.pop(context);
            if (product == null) {
              _createProduct(p);
            } else {
              _updateProduct(p);
            }
          },
        ),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadProducts),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToForm(),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? const Center(child: Text('No products. Add one!'))
              : ListView.builder(
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    return ListTile(
                      title: Text(product.name),
                      subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Qty: ${product.quantity}'),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteProduct(product.id!),
                          ),
                        ],
                      ),
                      onTap: () => _navigateToForm(product: product),
                    );
                  },
                ),
    );
  }
}
```

### Step 8: Add Route

📁 `lib/presentation/routes/app_routes.dart`

```dart
static const String products = '/products';

static Map<String, WidgetBuilder> get routes {
  return {
    // ... existing routes
    products: (context) => const ProductsPage(),
  };
}
```

---

## 5. Project Structure

```
lib/
├── main.dart                           # App entry point
├── core/                               # Shared utilities
│   ├── constants/                      # App, API, DB constants
│   ├── errors/                         # Custom exceptions
│   ├── theme/                          # App theming
│   └── utils/                          # Validators, helpers
├── data/                               # Data layer
│   ├── datasources/
│   │   ├── local/                      # SQLite operations
│   │   │   ├── database_helper.dart    # DB connection & queries
│   │   │   └── *_local_datasource.dart # Entity-specific DB ops
│   │   └── remote/                     # API operations
│   │       ├── api_client.dart         # HTTP client
│   │       └── *_remote_datasource.dart# Entity-specific API ops
│   ├── models/
│   │   ├── base/                       # Base classes
│   │   ├── entities/                   # Database models (toMap/fromMap)
│   │   └── dtos/                       # API models (toJson/fromJson)
│   └── repositories/                   # Combine local & remote
└── presentation/                       # UI layer
    ├── forms/                          # Input forms
    ├── pages/                          # Full screens
    ├── routes/                         # Navigation config
    └── widgets/                        # Reusable UI components
```

---

## Quick Reference

### Entity vs DTO

| Aspect | Entity | DTO |
|--------|--------|-----|
| Purpose | Database storage | API communication |
| Conversion | `toMap()` / `fromMap()` | `toJson()` / `fromJson()` |
| Location | `models/entities/` | `models/dtos/` |
| Naming | `*_entity.dart` | `*_dto.dart` |

### CRUD Summary

| Operation | Local (SQLite) | Remote (API) |
|-----------|----------------|--------------|
| Create | `insert()` | `POST /resource` |
| Read | `query()` | `GET /resource` |
| Update | `update()` | `PUT /resource/:id` |
| Delete | `delete()` | `DELETE /resource/:id` |

### Navigation Cheat Sheet

```dart
// Push
Navigator.pushNamed(context, '/route');

// Pop
Navigator.pop(context);

// Replace
Navigator.pushReplacementNamed(context, '/route');

// Clear & Push
Navigator.pushNamedAndRemoveUntil(context, '/route', (r) => false);
```

---

## Next Steps

1. **Practice**: Create another entity (e.g., `Category`, `Order`)
2. **Add validation**: Implement more validators in `validators.dart`
3. **Add search**: Implement search functionality in list pages
4. **Add state management**: Consider using Provider or Riverpod
5. **Add testing**: Write unit tests for datasources and repositories

Happy coding! 🚀
