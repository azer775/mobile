# Flutter Development Guide
## Complete Tutorial: Widgets, Forms, HTTP Requests, Database & State Management

This guide explains how to build Flutter features from scratch, using the Contribuable module as a reference example.

---

## Table of Contents

1. [Project Architecture Overview](#1-project-architecture-overview)
2. [Creating a New Entity](#2-creating-a-new-entity)
3. [Creating a Form Widget](#3-creating-a-form-widget)
4. [State Management](#4-state-management)
5. [Database Operations (SQLite)](#5-database-operations-sqlite)
6. [HTTP Requests (API Integration)](#6-http-requests-api-integration)
7. [Dependency Injection](#7-dependency-injection)
8. [Complete Example: Building a New Feature](#8-complete-example-building-a-new-feature)
9. [Best Practices](#9-best-practices)

---

## 1. Project Architecture Overview

### Folder Structure (Clean Architecture)

```
lib/
├── core/                    # Shared utilities & constants
│   ├── constants/           # App-wide constants (DB names, API URLs)
│   ├── errors/              # Custom exceptions
│   ├── services/            # Shared services (Auth, Network)
│   └── utils/               # Utility classes (Validators, Formatters)
│
├── data/                    # Data layer
│   ├── datasources/         # Data access (Local DB, Remote API)
│   │   ├── local/           # SQLite operations
│   │   └── remote/          # HTTP/API operations
│   ├── models/              # Data models
│   │   ├── entities/        # Database entities
│   │   └── enums/           # Enum definitions
│   └── repositories/        # Repository pattern (combines datasources)
│
├── presentation/            # UI layer
│   ├── forms/               # Form widgets
│   ├── pages/               # Full screen pages
│   └── widgets/             # Reusable UI components
│
└── main.dart                # App entry point
```

### Data Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                         USER INTERFACE                          │
│                    (Pages, Forms, Widgets)                      │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                         REPOSITORIES                            │
│           (Combines local & remote data sources)                │
└─────────────────────────────────────────────────────────────────┘
                                │
                ┌───────────────┴───────────────┐
                ▼                               ▼
┌───────────────────────────┐   ┌───────────────────────────────┐
│    LOCAL DATASOURCE       │   │      REMOTE DATASOURCE        │
│       (SQLite)            │   │        (HTTP/API)             │
└───────────────────────────┘   └───────────────────────────────┘
                │                               │
                ▼                               ▼
┌───────────────────────────┐   ┌───────────────────────────────┐
│    SQLite Database        │   │      REST API Server          │
└───────────────────────────┘   └───────────────────────────────┘
```

---

## 2. Creating a New Entity

An **Entity** represents your data model - the structure of data stored in the database.

### Step 1: Define the Entity Class

Create a new file: `lib/data/models/entities/product_entity.dart`

```dart
import 'dart:convert';
import 'base_entity.dart';

/// Product Entity for database storage
/// 
/// This class:
/// - Defines the data structure
/// - Handles serialization (toMap) for database storage
/// - Handles deserialization (fromMap) for reading from database
/// - Handles JSON conversion for API communication
class ProductEntity extends BaseEntity {
  // ---------------------------------------------------------------------------
  // FIELDS - Define all properties of your entity
  // ---------------------------------------------------------------------------
  String name;
  String? description;
  double price;
  int quantity;
  String? imageUrl;
  int? categoryId;  // Foreign key example
  bool isActive;
  
  // Audit fields (who created/modified and when)
  String createdBy;
  DateTime? createdAt;
  String? updatedBy;
  DateTime? updatedAt;

  // ---------------------------------------------------------------------------
  // CONSTRUCTOR
  // ---------------------------------------------------------------------------
  ProductEntity({
    super.id,                    // From BaseEntity (nullable for new records)
    required this.name,
    this.description,
    required this.price,
    this.quantity = 0,
    this.imageUrl,
    this.categoryId,
    this.isActive = true,
    required this.createdBy,
    this.createdAt,
    this.updatedBy,
    this.updatedAt,
  });

  // ---------------------------------------------------------------------------
  // COMPUTED PROPERTIES - Derived values
  // ---------------------------------------------------------------------------
  
  /// Check if product is in stock
  bool get isInStock => quantity > 0;
  
  /// Get formatted price
  String get formattedPrice => '\$${price.toStringAsFixed(2)}';

  // ---------------------------------------------------------------------------
  // TABLE NAME - Used by database helper
  // ---------------------------------------------------------------------------
  @override
  String get tableName => 'products';

  // ---------------------------------------------------------------------------
  // SERIALIZATION - Convert to Map for database storage
  // ---------------------------------------------------------------------------
  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'quantity': quantity,
      'image_url': imageUrl,
      'category_id': categoryId,
      'is_active': isActive ? 1 : 0,  // SQLite stores booleans as integers
      'created_by': createdBy,
      'created_at': createdAt?.toIso8601String(),
      'updated_by': updatedBy,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // ---------------------------------------------------------------------------
  // DESERIALIZATION - Create entity from database Map
  // ---------------------------------------------------------------------------
  factory ProductEntity.fromMap(Map<String, dynamic> map) {
    return ProductEntity(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      price: (map['price'] as num).toDouble(),
      quantity: map['quantity'] as int? ?? 0,
      imageUrl: map['image_url'] as String?,
      categoryId: map['category_id'] as int?,
      isActive: (map['is_active'] as int?) == 1,
      createdBy: map['created_by'] as String? ?? 'SYSTEM',
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at'] as String) 
          : null,
      updatedBy: map['updated_by'] as String?,
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at'] as String) 
          : null,
    );
  }

  // ---------------------------------------------------------------------------
  // JSON SERIALIZATION - For API communication
  // ---------------------------------------------------------------------------
  
  /// Convert to JSON string
  String toJson() => jsonEncode(toMap());
  
  /// Create from JSON string
  factory ProductEntity.fromJson(String jsonString) {
    return ProductEntity.fromMap(jsonDecode(jsonString));
  }
  
  /// Create from API response (may have different field names)
  factory ProductEntity.fromApiResponse(Map<String, dynamic> json) {
    return ProductEntity(
      id: json['id'] as int?,
      name: json['product_name'] as String,  // API might use different names
      description: json['product_description'] as String?,
      price: (json['unit_price'] as num).toDouble(),
      quantity: json['stock_quantity'] as int? ?? 0,
      imageUrl: json['image'] as String?,
      categoryId: json['category_id'] as int?,
      isActive: json['active'] as bool? ?? true,
      createdBy: json['created_by'] as String? ?? 'API',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : null,
    );
  }
  
  /// Convert to API request format
  Map<String, dynamic> toApiRequest() {
    return {
      'product_name': name,
      'product_description': description,
      'unit_price': price,
      'stock_quantity': quantity,
      'image': imageUrl,
      'category_id': categoryId,
      'active': isActive,
    };
  }

  // ---------------------------------------------------------------------------
  // COPY WITH - Create modified copy (immutability pattern)
  // ---------------------------------------------------------------------------
  ProductEntity copyWith({
    int? id,
    String? name,
    String? description,
    double? price,
    int? quantity,
    String? imageUrl,
    int? categoryId,
    bool? isActive,
    String? createdBy,
    DateTime? createdAt,
    String? updatedBy,
    DateTime? updatedAt,
  }) {
    return ProductEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
      categoryId: categoryId ?? this.categoryId,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
```

### Step 2: Create the Base Entity (if not exists)

```dart
// lib/data/models/entities/base_entity.dart

/// Base class for all entities
/// Provides common functionality like id and table name
abstract class BaseEntity {
  int? id;
  DateTime? createdAt;
  DateTime? updatedAt;

  BaseEntity({
    this.id,
    this.createdAt,
    this.updatedAt,
  });

  /// The database table name for this entity
  String get tableName;

  /// Convert entity to a map for database operations
  Map<String, dynamic> toMap();
}
```

---

## 3. Creating a Form Widget

A **Form Widget** collects user input and creates/updates an entity.

### Form Widget Structure

```dart
// lib/presentation/forms/product_form.dart

import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/utils/validators.dart';
import '../../data/models/entities/product_entity.dart';

/// Product Form Widget
/// 
/// WIDGET TYPE: StatefulWidget
/// - Why? Because forms need to manage state (input values, loading, errors)
/// 
/// PARAMETERS:
/// - product: Optional existing product (null = create mode, not null = edit mode)
/// - onSave: Callback function when form is submitted successfully
/// - currentUser: Username for audit fields
class ProductForm extends StatefulWidget {
  final ProductEntity? product;           // null = create, not null = edit
  final Function(ProductEntity) onSave;   // Callback to parent
  final String currentUser;

  const ProductForm({
    super.key,
    this.product,
    required this.onSave,
    required this.currentUser,
  });

  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  // ===========================================================================
  // FORM KEY - For validation
  // ===========================================================================
  // GlobalKey<FormState> connects to the Form widget and enables:
  // - _formKey.currentState!.validate() - Validate all fields
  // - _formKey.currentState!.save() - Call onSaved on all fields
  // - _formKey.currentState!.reset() - Reset all fields
  final _formKey = GlobalKey<FormState>();

  // ===========================================================================
  // TEXT CONTROLLERS
  // ===========================================================================
  // Each TextFormField needs a controller to:
  // 1. Pre-populate with existing values (edit mode)
  // 2. Read current values on submit
  // 3. Dispose properly to avoid memory leaks
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _quantityController;

  // ===========================================================================
  // STATE VARIABLES
  // ===========================================================================
  int? _categoryId;           // Selected category
  bool _isActive = true;      // Active toggle
  bool _isLoading = false;    // Show loading indicator

  // ===========================================================================
  // COMPUTED PROPERTIES
  // ===========================================================================
  bool get _isEditing => widget.product != null;

  // ===========================================================================
  // LIFECYCLE: initState
  // ===========================================================================
  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with existing values or empty
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _priceController = TextEditingController(
      text: p?.price.toString() ?? '',
    );
    _quantityController = TextEditingController(
      text: p?.quantity.toString() ?? '0',
    );
    
    // Initialize other state
    _categoryId = p?.categoryId;
    _isActive = p?.isActive ?? true;
  }

  // ===========================================================================
  // LIFECYCLE: dispose
  // ===========================================================================
  @override
  void dispose() {
    // CRITICAL: Always dispose controllers to prevent memory leaks
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // FORM SUBMISSION
  // ===========================================================================
  Future<void> _onSubmit() async {
    // Step 1: Validate all form fields
    if (!_formKey.currentState!.validate()) {
      return; // Stop if validation fails
    }

    // Step 2: Show loading indicator
    setState(() => _isLoading = true);

    try {
      // Step 3: Create entity from form data
      final product = ProductEntity(
        id: widget.product?.id,  // Keep existing ID for updates
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        quantity: int.parse(_quantityController.text.trim()),
        categoryId: _categoryId,
        isActive: _isActive,
        createdBy: widget.product?.createdBy ?? widget.currentUser,
        createdAt: widget.product?.createdAt,
        updatedBy: _isEditing ? widget.currentUser : null,
        updatedAt: DateTime.now(),
      );

      // Step 4: Call parent's callback
      widget.onSave(product);
      
    } catch (e) {
      // Step 5: Handle errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      // Step 6: Hide loading indicator
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ===========================================================================
  // BUILD METHOD
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Product' : 'New Product'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,  // Connect form to our key
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ----- NAME FIELD -----
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name *',
                  prefixIcon: Icon(Icons.shopping_bag),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Product name is required';
                  }
                  if (value.trim().length < 3) {
                    return 'Name must be at least 3 characters';
                  }
                  return null; // Valid
                },
              ),
              const SizedBox(height: 16),

              // ----- DESCRIPTION FIELD -----
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                // No validator - optional field
              ),
              const SizedBox(height: 16),

              // ----- PRICE FIELD -----
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price *',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Price is required';
                  }
                  final price = double.tryParse(value.trim());
                  if (price == null) {
                    return 'Enter a valid number';
                  }
                  if (price < 0) {
                    return 'Price cannot be negative';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ----- QUANTITY FIELD -----
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  prefixIcon: Icon(Icons.inventory),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final qty = int.tryParse(value.trim());
                    if (qty == null || qty < 0) {
                      return 'Enter a valid quantity';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ----- ACTIVE SWITCH -----
              SwitchListTile(
                title: const Text('Active'),
                subtitle: const Text('Product is available for sale'),
                value: _isActive,
                onChanged: (value) {
                  setState(() => _isActive = value);
                },
              ),
              const SizedBox(height: 24),

              // ----- SUBMIT BUTTON -----
              ElevatedButton(
                onPressed: _isLoading ? null : _onSubmit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _isEditing ? 'Update' : 'Save',
                        style: const TextStyle(fontSize: 16),
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

### Form Validation Patterns

```dart
// lib/core/utils/validators.dart

/// Centralized validation functions
/// 
/// Why centralize?
/// - Consistency across all forms
/// - Easy to update validation rules
/// - Reusable across the app
class Validators {
  /// Required field validator
  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Email validator
  static String? email(String? value) {
    if (value == null || value.isEmpty) return null;
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// Phone number validator
  static String? phone(String? value) {
    if (value == null || value.isEmpty) return null;
    
    // Remove spaces and dashes for validation
    final cleanNumber = value.replaceAll(RegExp(r'[\s-]'), '');
    if (cleanNumber.length < 9 || cleanNumber.length > 15) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  /// Minimum length validator
  static String? minLength(String? value, int minLength, {String fieldName = 'This field'}) {
    if (value == null || value.isEmpty) return null;
    
    if (value.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    return null;
  }

  /// Numeric validator
  static String? numeric(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.isEmpty) return null;
    
    if (double.tryParse(value) == null) {
      return '$fieldName must be a number';
    }
    return null;
  }

  /// Range validator
  static String? range(String? value, double min, double max, {String fieldName = 'Value'}) {
    if (value == null || value.isEmpty) return null;
    
    final number = double.tryParse(value);
    if (number == null) {
      return '$fieldName must be a number';
    }
    if (number < min || number > max) {
      return '$fieldName must be between $min and $max';
    }
    return null;
  }
}
```

---

## 4. State Management

### Understanding State in Flutter

**State** = Data that can change over time and affects the UI.

### Types of State

| Type | Scope | Example | Solution |
|------|-------|---------|----------|
| **Ephemeral State** | Single widget | Form input, animation | `setState()` |
| **App State** | Multiple widgets | User auth, cart | Provider, Riverpod, BLoC |
| **Server State** | From API | Product list | Repository pattern |

### 4.1 Local State with setState

```dart
class _MyWidgetState extends State<MyWidget> {
  // State variables
  int _counter = 0;
  bool _isLoading = false;
  List<Product> _products = [];

  // Update state
  void _increment() {
    setState(() {
      _counter++;  // UI rebuilds after this
    });
  }

  // Async state update
  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);  // Show loading
    
    try {
      final products = await _repository.getAll();
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Show error
    }
  }
}
```

### 4.2 State Management with Provider

**Provider** is the recommended simple state management solution.

#### Step 1: Add dependency

```yaml
# pubspec.yaml
dependencies:
  provider: ^6.1.0
```

#### Step 2: Create a ChangeNotifier

```dart
// lib/providers/product_provider.dart

import 'package:flutter/foundation.dart';
import '../data/models/entities/product_entity.dart';
import '../data/repositories/product_repository.dart';

/// Product state management using ChangeNotifier
/// 
/// ChangeNotifier:
/// - Manages state
/// - Notifies listeners when state changes
/// - Triggers UI rebuilds
class ProductProvider extends ChangeNotifier {
  final ProductRepository _repository;

  // ---------------------------------------------------------------------------
  // STATE
  // ---------------------------------------------------------------------------
  List<ProductEntity> _products = [];
  bool _isLoading = false;
  String? _error;

  // ---------------------------------------------------------------------------
  // GETTERS - Expose state to UI (read-only)
  // ---------------------------------------------------------------------------
  List<ProductEntity> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Computed getters
  int get productCount => _products.length;
  List<ProductEntity> get activeProducts => 
      _products.where((p) => p.isActive).toList();

  // ---------------------------------------------------------------------------
  // CONSTRUCTOR
  // ---------------------------------------------------------------------------
  ProductProvider(this._repository);

  // ---------------------------------------------------------------------------
  // ACTIONS - Methods that modify state
  // ---------------------------------------------------------------------------

  /// Load all products
  Future<void> loadProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();  // Trigger UI rebuild

    try {
      _products = await _repository.getAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();  // Trigger UI rebuild
    }
  }

  /// Add a new product
  Future<void> addProduct(ProductEntity product) async {
    _isLoading = true;
    notifyListeners();

    try {
      final id = await _repository.insert(product);
      final newProduct = product.copyWith(id: id);
      _products.add(newProduct);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update existing product
  Future<void> updateProduct(ProductEntity product) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.update(product);
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = product;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Delete product
  Future<void> deleteProduct(int id) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.delete(id);
      _products.removeWhere((p) => p.id == id);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
```

#### Step 3: Provide at App Level

```dart
// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    // MultiProvider allows providing multiple providers
    MultiProvider(
      providers: [
        // ChangeNotifierProvider creates and provides the provider
        ChangeNotifierProvider(
          create: (_) => ProductProvider(ProductRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),
        // Add more providers as needed
      ],
      child: const MyApp(),
    ),
  );
}
```

#### Step 4: Consume in Widgets

```dart
// lib/presentation/pages/products_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProductsPage extends StatefulWidget {
  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  @override
  void initState() {
    super.initState();
    // Load products on page init
    // 'listen: false' because we're not in build method
    context.read<ProductProvider>().loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: Consumer<ProductProvider>(
        // Consumer rebuilds when provider notifies
        builder: (context, provider, child) {
          // Handle loading state
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Handle error state
          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${provider.error}'),
                  ElevatedButton(
                    onPressed: () => provider.loadProducts(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Handle empty state
          if (provider.products.isEmpty) {
            return const Center(child: Text('No products found'));
          }

          // Show products list
          return ListView.builder(
            itemCount: provider.products.length,
            itemBuilder: (context, index) {
              final product = provider.products[index];
              return ListTile(
                title: Text(product.name),
                subtitle: Text(product.formattedPrice),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => provider.deleteProduct(product.id!),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddProduct(),
        child: const Icon(Icons.add),
      ),
    );
  }
  
  void _navigateToAddProduct() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductForm(
          onSave: (product) async {
            // Access provider and add product
            await context.read<ProductProvider>().addProduct(product);
            Navigator.pop(context);
          },
          currentUser: 'CurrentUser',
        ),
      ),
    );
  }
}
```

### 4.3 Provider Access Methods

```dart
// In build() method - Use context.watch() or Consumer
// These WILL rebuild when state changes

// Method 1: context.watch()
final products = context.watch<ProductProvider>().products;

// Method 2: Consumer widget
Consumer<ProductProvider>(
  builder: (context, provider, child) {
    return Text('Count: ${provider.productCount}');
  },
)

// Outside build() or for actions - Use context.read()
// Does NOT rebuild when state changes

// In onPressed, initState, etc:
context.read<ProductProvider>().loadProducts();
context.read<ProductProvider>().addProduct(product);
```

---

## 5. Database Operations (SQLite)

### 5.1 Database Helper

```dart
// lib/data/datasources/local/database_helper.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Singleton Database Helper
/// 
/// Singleton Pattern ensures only one database connection exists
class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _database;

  // Private constructor
  DatabaseHelper._();

  // Singleton accessor
  static DatabaseHelper get instance {
    _instance ??= DatabaseHelper._();
    return _instance!;
  }

  // Database getter with lazy initialization
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  // Initialize database
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'app_database.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Create tables
  Future<void> _onCreate(Database db, int version) async {
    // Products table
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        price REAL NOT NULL,
        quantity INTEGER DEFAULT 0,
        image_url TEXT,
        category_id INTEGER,
        is_active INTEGER DEFAULT 1,
        created_by TEXT NOT NULL,
        created_at TEXT,
        updated_by TEXT,
        updated_at TEXT
      )
    ''');

    // Categories table
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT
      )
    ''');
  }

  // Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new column example
      await db.execute('ALTER TABLE products ADD COLUMN sku TEXT');
    }
  }

  // ---------------------------------------------------------------------------
  // GENERIC CRUD METHODS
  // ---------------------------------------------------------------------------

  /// Insert a record
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data);
  }

  /// Update a record
  Future<int> update(
    String table,
    Map<String, dynamic> data, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return await db.update(table, data, where: where, whereArgs: whereArgs);
  }

  /// Delete a record
  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  /// Query records
  Future<List<Map<String, dynamic>>> query(
    String table, {
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    final db = await database;
    return await db.query(
      table,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
    );
  }

  /// Query all records
  Future<List<Map<String, dynamic>>> queryAll(String table) async {
    final db = await database;
    return await db.query(table);
  }
}
```

### 5.2 Local Datasource

```dart
// lib/data/datasources/local/product_local_datasource.dart

import 'database_helper.dart';
import '../../models/entities/product_entity.dart';

/// Product Local Datasource
/// 
/// Handles all SQLite operations for products
/// Converts between entity objects and database maps
class ProductLocalDatasource {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Insert a new product
  Future<int> insert(ProductEntity product) async {
    final map = product.toMap();
    map.remove('id');  // Let SQLite auto-generate ID
    map['created_at'] = DateTime.now().toIso8601String();
    return await _dbHelper.insert('products', map);
  }

  /// Get all products
  Future<List<ProductEntity>> getAll() async {
    final maps = await _dbHelper.queryAll('products');
    return maps.map((map) => ProductEntity.fromMap(map)).toList();
  }

  /// Get product by ID
  Future<ProductEntity?> getById(int id) async {
    final maps = await _dbHelper.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return ProductEntity.fromMap(maps.first);
  }

  /// Search products
  Future<List<ProductEntity>> search(String query) async {
    final maps = await _dbHelper.query(
      'products',
      where: 'name LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );
    return maps.map((map) => ProductEntity.fromMap(map)).toList();
  }

  /// Update product
  Future<int> update(ProductEntity product) async {
    final map = product.toMap();
    map['updated_at'] = DateTime.now().toIso8601String();
    return await _dbHelper.update(
      'products',
      map,
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  /// Delete product
  Future<int> delete(int id) async {
    return await _dbHelper.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get active products only
  Future<List<ProductEntity>> getActive() async {
    final maps = await _dbHelper.query(
      'products',
      where: 'is_active = ?',
      whereArgs: [1],
    );
    return maps.map((map) => ProductEntity.fromMap(map)).toList();
  }
}
```

---

## 6. HTTP Requests (API Integration)

### 6.1 HTTP Client Setup

```yaml
# pubspec.yaml
dependencies:
  http: ^1.1.0
  # OR use dio for more features:
  # dio: ^5.3.0
```

### 6.2 API Configuration

```dart
// lib/core/constants/api_constants.dart

/// API Configuration Constants
class ApiConstants {
  // Base URL
  static const String baseUrl = 'https://api.example.com/v1';
  
  // Endpoints
  static const String products = '/products';
  static const String categories = '/categories';
  static const String auth = '/auth';
  
  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Headers
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  static Map<String, String> authHeaders(String token) => {
    ...defaultHeaders,
    'Authorization': 'Bearer $token',
  };
}
```

### 6.3 API Service

```dart
// lib/core/services/api_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../errors/exceptions.dart';

/// Generic API Service for HTTP requests
/// 
/// Handles:
/// - GET, POST, PUT, DELETE requests
/// - JSON encoding/decoding
/// - Error handling
/// - Authentication headers
class ApiService {
  final http.Client _client;
  String? _authToken;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Set authentication token
  void setAuthToken(String token) {
    _authToken = token;
  }

  /// Clear authentication token
  void clearAuthToken() {
    _authToken = null;
  }

  /// Get headers with optional auth
  Map<String, String> get _headers {
    if (_authToken != null) {
      return ApiConstants.authHeaders(_authToken!);
    }
    return ApiConstants.defaultHeaders;
  }

  // ---------------------------------------------------------------------------
  // HTTP METHODS
  // ---------------------------------------------------------------------------

  /// GET request
  Future<dynamic> get(String endpoint, {Map<String, String>? queryParams}) async {
    try {
      var uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final response = await _client
          .get(uri, headers: _headers)
          .timeout(ApiConstants.connectTimeout);

      return _handleResponse(response);
    } on SocketException {
      throw NetworkException('No internet connection');
    } on HttpException {
      throw NetworkException('HTTP error occurred');
    }
  }

  /// POST request
  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');

      final response = await _client
          .post(
            uri,
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConstants.connectTimeout);

      return _handleResponse(response);
    } on SocketException {
      throw NetworkException('No internet connection');
    }
  }

  /// PUT request
  Future<dynamic> put(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');

      final response = await _client
          .put(
            uri,
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConstants.connectTimeout);

      return _handleResponse(response);
    } on SocketException {
      throw NetworkException('No internet connection');
    }
  }

  /// DELETE request
  Future<dynamic> delete(String endpoint) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');

      final response = await _client
          .delete(uri, headers: _headers)
          .timeout(ApiConstants.connectTimeout);

      return _handleResponse(response);
    } on SocketException {
      throw NetworkException('No internet connection');
    }
  }

  // ---------------------------------------------------------------------------
  // RESPONSE HANDLING
  // ---------------------------------------------------------------------------

  dynamic _handleResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
      case 201:
        if (response.body.isEmpty) return null;
        return jsonDecode(response.body);
      case 400:
        throw BadRequestException(_parseError(response.body));
      case 401:
        throw UnauthorizedException('Session expired. Please login again.');
      case 403:
        throw ForbiddenException('You do not have permission.');
      case 404:
        throw NotFoundException('Resource not found.');
      case 422:
        throw ValidationException(_parseError(response.body));
      case 500:
        throw ServerException('Server error. Please try again later.');
      default:
        throw NetworkException('Unexpected error: ${response.statusCode}');
    }
  }

  String _parseError(String body) {
    try {
      final json = jsonDecode(body);
      return json['message'] ?? json['error'] ?? 'Unknown error';
    } catch (e) {
      return body;
    }
  }
}
```

### 6.4 Remote Datasource

```dart
// lib/data/datasources/remote/product_remote_datasource.dart

import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../models/entities/product_entity.dart';

/// Product Remote Datasource
/// 
/// Handles all API operations for products
class ProductRemoteDatasource {
  final ApiService _apiService;

  ProductRemoteDatasource(this._apiService);

  /// Get all products from API
  Future<List<ProductEntity>> getAll() async {
    final response = await _apiService.get(ApiConstants.products);
    
    final List<dynamic> data = response['data'] ?? response;
    return data.map((json) => ProductEntity.fromApiResponse(json)).toList();
  }

  /// Get single product by ID
  Future<ProductEntity> getById(int id) async {
    final response = await _apiService.get('${ApiConstants.products}/$id');
    return ProductEntity.fromApiResponse(response['data'] ?? response);
  }

  /// Create new product
  Future<ProductEntity> create(ProductEntity product) async {
    final response = await _apiService.post(
      ApiConstants.products,
      body: product.toApiRequest(),
    );
    return ProductEntity.fromApiResponse(response['data'] ?? response);
  }

  /// Update product
  Future<ProductEntity> update(ProductEntity product) async {
    final response = await _apiService.put(
      '${ApiConstants.products}/${product.id}',
      body: product.toApiRequest(),
    );
    return ProductEntity.fromApiResponse(response['data'] ?? response);
  }

  /// Delete product
  Future<void> delete(int id) async {
    await _apiService.delete('${ApiConstants.products}/$id');
  }

  /// Search products
  Future<List<ProductEntity>> search(String query) async {
    final response = await _apiService.get(
      ApiConstants.products,
      queryParams: {'search': query},
    );
    
    final List<dynamic> data = response['data'] ?? response;
    return data.map((json) => ProductEntity.fromApiResponse(json)).toList();
  }
}
```

### 6.5 Custom Exceptions

```dart
// lib/core/errors/exceptions.dart

/// Base exception class
abstract class AppException implements Exception {
  final String message;
  AppException(this.message);

  @override
  String toString() => message;
}

/// Network related exceptions
class NetworkException extends AppException {
  NetworkException(super.message);
}

/// Server errors (5xx)
class ServerException extends AppException {
  ServerException(super.message);
}

/// Authentication errors (401)
class UnauthorizedException extends AppException {
  UnauthorizedException(super.message);
}

/// Permission errors (403)
class ForbiddenException extends AppException {
  ForbiddenException(super.message);
}

/// Not found errors (404)
class NotFoundException extends AppException {
  NotFoundException(super.message);
}

/// Bad request errors (400)
class BadRequestException extends AppException {
  BadRequestException(super.message);
}

/// Validation errors (422)
class ValidationException extends AppException {
  ValidationException(super.message);
}

/// Database errors
class DatabaseException extends AppException {
  DatabaseException(super.message);
}

/// Cache errors
class CacheException extends AppException {
  CacheException(super.message);
}
```

---

## 7. Dependency Injection

**Dependency Injection (DI)** = Providing dependencies to a class from outside rather than creating them internally.

### Why Use DI?

| Without DI | With DI |
|------------|---------|
| Hard to test | Easy to mock |
| Tight coupling | Loose coupling |
| Hard to change implementations | Easy to swap |

### 7.1 Manual Dependency Injection

```dart
// Bad: Creating dependencies internally
class ProductProvider {
  final _repository = ProductRepository();  // ❌ Hard-coded
}

// Good: Receiving dependencies from outside
class ProductProvider {
  final ProductRepository _repository;
  
  ProductProvider(this._repository);  // ✅ Injected
}
```

### 7.2 Using get_it Package

```yaml
# pubspec.yaml
dependencies:
  get_it: ^7.6.0
```

#### Setup Service Locator

```dart
// lib/core/di/injection_container.dart

import 'package:get_it/get_it.dart';
import '../services/api_service.dart';
import '../../data/datasources/local/database_helper.dart';
import '../../data/datasources/local/product_local_datasource.dart';
import '../../data/datasources/remote/product_remote_datasource.dart';
import '../../data/repositories/product_repository.dart';
import '../../providers/product_provider.dart';

/// Global service locator
final sl = GetIt.instance;

/// Initialize all dependencies
Future<void> initDependencies() async {
  // ---------------------------------------------------------------------------
  // CORE - Services that other things depend on
  // ---------------------------------------------------------------------------
  
  // Database Helper (Singleton - same instance always)
  sl.registerLazySingleton<DatabaseHelper>(() => DatabaseHelper.instance);
  
  // API Service (Singleton)
  sl.registerLazySingleton<ApiService>(() => ApiService());

  // ---------------------------------------------------------------------------
  // DATA SOURCES
  // ---------------------------------------------------------------------------
  
  // Local datasources (Singleton)
  sl.registerLazySingleton<ProductLocalDatasource>(
    () => ProductLocalDatasource(),
  );
  
  // Remote datasources (Singleton)
  sl.registerLazySingleton<ProductRemoteDatasource>(
    () => ProductRemoteDatasource(sl()),  // sl() gets ApiService
  );

  // ---------------------------------------------------------------------------
  // REPOSITORIES
  // ---------------------------------------------------------------------------
  
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepository(
      localDatasource: sl(),   // Gets ProductLocalDatasource
      remoteDatasource: sl(),  // Gets ProductRemoteDatasource
    ),
  );

  // ---------------------------------------------------------------------------
  // PROVIDERS / BLOCS (Factory - new instance each time)
  // ---------------------------------------------------------------------------
  
  sl.registerFactory<ProductProvider>(
    () => ProductProvider(sl()),  // Gets ProductRepository
  );
}

// Registration Types:
// - registerSingleton: Creates immediately, same instance always
// - registerLazySingleton: Creates on first use, same instance always
// - registerFactory: Creates new instance each time
```

#### Use in App

```dart
// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/di/injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize dependencies
  await di.initDependencies();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => di.sl<ProductProvider>(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}
```

### 7.3 Repository Pattern

**Repository** = Abstraction layer between data sources and business logic.

```dart
// lib/data/repositories/product_repository.dart

import '../datasources/local/product_local_datasource.dart';
import '../datasources/remote/product_remote_datasource.dart';
import '../models/entities/product_entity.dart';

/// Product Repository
/// 
/// Combines local and remote data sources.
/// Decides where to get data from (cache vs API).
/// Handles offline-first strategy.
class ProductRepository {
  final ProductLocalDatasource _localDatasource;
  final ProductRemoteDatasource _remoteDatasource;

  ProductRepository({
    required ProductLocalDatasource localDatasource,
    required ProductRemoteDatasource remoteDatasource,
  })  : _localDatasource = localDatasource,
        _remoteDatasource = remoteDatasource;

  /// Get all products
  /// Strategy: Try remote first, fallback to local, cache results
  Future<List<ProductEntity>> getAll({bool forceRefresh = false}) async {
    try {
      if (forceRefresh) {
        // Fetch from API
        final remoteProducts = await _remoteDatasource.getAll();
        
        // Cache locally
        for (final product in remoteProducts) {
          final existing = await _localDatasource.getById(product.id!);
          if (existing != null) {
            await _localDatasource.update(product);
          } else {
            await _localDatasource.insert(product);
          }
        }
        
        return remoteProducts;
      }
      
      // Try local first
      final localProducts = await _localDatasource.getAll();
      if (localProducts.isNotEmpty) {
        return localProducts;
      }
      
      // Fallback to remote
      return await _remoteDatasource.getAll();
      
    } catch (e) {
      // On error, try local cache
      return await _localDatasource.getAll();
    }
  }

  /// Insert product (local + remote)
  Future<int> insert(ProductEntity product) async {
    // Save locally first
    final localId = await _localDatasource.insert(product);
    
    try {
      // Sync to remote
      final remoteProduct = await _remoteDatasource.create(product);
      
      // Update local with remote ID if different
      if (remoteProduct.id != localId) {
        await _localDatasource.update(
          product.copyWith(id: remoteProduct.id),
        );
        return remoteProduct.id!;
      }
    } catch (e) {
      // Remote failed, but local succeeded
      // Could add to sync queue for later
    }
    
    return localId;
  }

  /// Update product
  Future<void> update(ProductEntity product) async {
    // Update locally
    await _localDatasource.update(product);
    
    try {
      // Sync to remote
      await _remoteDatasource.update(product);
    } catch (e) {
      // Add to sync queue for later
    }
  }

  /// Delete product
  Future<void> delete(int id) async {
    // Delete locally
    await _localDatasource.delete(id);
    
    try {
      // Delete remotely
      await _remoteDatasource.delete(id);
    } catch (e) {
      // Add to sync queue for later
    }
  }
}
```

---

## 8. Complete Example: Building a New Feature

Let's build a complete "Category" feature from scratch.

### Step 1: Create Entity

```dart
// lib/data/models/entities/category_entity.dart

class CategoryEntity {
  int? id;
  String name;
  String? description;
  String? iconName;
  int sortOrder;
  bool isActive;

  CategoryEntity({
    this.id,
    required this.name,
    this.description,
    this.iconName,
    this.sortOrder = 0,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'icon_name': iconName,
    'sort_order': sortOrder,
    'is_active': isActive ? 1 : 0,
  };

  factory CategoryEntity.fromMap(Map<String, dynamic> map) => CategoryEntity(
    id: map['id'],
    name: map['name'],
    description: map['description'],
    iconName: map['icon_name'],
    sortOrder: map['sort_order'] ?? 0,
    isActive: map['is_active'] == 1,
  );
}
```

### Step 2: Create Local Datasource

```dart
// lib/data/datasources/local/category_local_datasource.dart

class CategoryLocalDatasource {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> insert(CategoryEntity category) async {
    final map = category.toMap();
    map.remove('id');
    return await _dbHelper.insert('categories', map);
  }

  Future<List<CategoryEntity>> getAll() async {
    final maps = await _dbHelper.queryAll('categories');
    return maps.map((m) => CategoryEntity.fromMap(m)).toList();
  }

  Future<int> update(CategoryEntity category) async {
    return await _dbHelper.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> delete(int id) async {
    return await _dbHelper.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
```

### Step 3: Create Form

```dart
// lib/presentation/forms/category_form.dart

class CategoryForm extends StatefulWidget {
  final CategoryEntity? category;
  final Function(CategoryEntity) onSave;

  const CategoryForm({super.key, this.category, required this.onSave});

  @override
  State<CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends State<CategoryForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _descriptionController = TextEditingController(text: widget.category?.description ?? '');
    _isActive = widget.category?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final category = CategoryEntity(
      id: widget.category?.id,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      isActive: _isActive,
    );

    widget.onSave(category);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category == null ? 'New Category' : 'Edit Category'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name *'),
              validator: (v) => v?.isEmpty == true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Active'),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submit,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Step 4: Create List Page

```dart
// lib/presentation/pages/categories_page.dart

class CategoriesPage extends StatefulWidget {
  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final _datasource = CategoryLocalDatasource();
  List<CategoryEntity> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      _categories = await _datasource.getAll();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _navigateToForm([CategoryEntity? category]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryForm(
          category: category,
          onSave: (cat) async {
            if (cat.id == null) {
              await _datasource.insert(cat);
            } else {
              await _datasource.update(cat);
            }
            Navigator.pop(context);
            _loadCategories();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToForm(),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                return ListTile(
                  title: Text(cat.name),
                  subtitle: Text(cat.description ?? ''),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      await _datasource.delete(cat.id!);
                      _loadCategories();
                    },
                  ),
                  onTap: () => _navigateToForm(cat),
                );
              },
            ),
    );
  }
}
```

---

## 9. Best Practices

### Code Organization

```dart
// ✅ DO: One class per file
// ✅ DO: Name files with snake_case
// ✅ DO: Group related files in folders

// ❌ DON'T: Multiple classes in one file
// ❌ DON'T: Mix naming conventions
```

### State Management

```dart
// ✅ DO: Keep state minimal
// ✅ DO: Use computed properties
// ✅ DO: Check mounted before setState

if (mounted) {
  setState(() => _isLoading = false);
}

// ❌ DON'T: Store derived data as state
// ❌ DON'T: Call setState after dispose
```

### Error Handling

```dart
// ✅ DO: Use try-catch-finally
try {
  await _doSomething();
} catch (e) {
  _showError(e.toString());
} finally {
  _hideLoading();
}

// ✅ DO: Create custom exceptions
// ❌ DON'T: Catch and ignore errors
// ❌ DON'T: Show raw error messages to users
```

### Performance

```dart
// ✅ DO: Use const constructors
const SizedBox(height: 16);
const Text('Hello');

// ✅ DO: Dispose controllers
@override
void dispose() {
  _controller.dispose();
  super.dispose();
}

// ✅ DO: Use ListView.builder for large lists
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(items[index]),
);

// ❌ DON'T: Create lists with ListView
// ❌ DON'T: Forget to dispose resources
```

### Testing

```dart
// ✅ DO: Write testable code
// - Use dependency injection
// - Keep widgets small
// - Separate business logic

// ✅ DO: Create interfaces for mocking
abstract class ProductRepository {
  Future<List<ProductEntity>> getAll();
}

// ❌ DON'T: Make untestable code
// - Hard-coded dependencies
// - Giant widgets
// - Logic in UI
```

---

## Quick Reference

| Task | File Location | Key Class |
|------|---------------|-----------|
| Create entity | `lib/data/models/entities/` | `XxxEntity` |
| Create form | `lib/presentation/forms/` | `XxxForm` |
| Create page | `lib/presentation/pages/` | `XxxPage` |
| Database ops | `lib/data/datasources/local/` | `XxxLocalDatasource` |
| API calls | `lib/data/datasources/remote/` | `XxxRemoteDatasource` |
| State mgmt | `lib/providers/` | `XxxProvider` |
| Validation | `lib/core/utils/` | `Validators` |
| Constants | `lib/core/constants/` | `XxxConstants` |

---

*Document created: January 2026*
*Based on Flutter 3.x / Dart 3.x*
