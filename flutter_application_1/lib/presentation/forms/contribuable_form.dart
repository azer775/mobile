// =============================================================================
// CONTRIBUABLE FORM - Taxpayer Registration & Editing Form
// =============================================================================
//
// This form handles the creation and editing of "Contribuable" (taxpayer) records.
// It demonstrates several key Flutter concepts and patterns:
//
// ARCHITECTURE OVERVIEW:
// ----------------------
// 1. StatefulWidget pattern for managing form state
// 2. Form validation using GlobalKey<FormState>
// 3. TextEditingController for input field management
// 4. Separation of concerns with service classes (Camera, Location)
// 5. Async data loading for reference tables (dropdown data)
//
// KEY FEATURES:
// -------------
// - Dual mode: Create new contribuable OR Edit existing one
// - Dynamic form fields based on taxpayer type (physical person vs company)
// - Photo capture from camera or gallery with local storage
// - GPS location capture with permission handling
// - Reference data dropdowns (activity types, zone types)
// - Form validation with custom validators
// - Loading states for async operations
//
// DATA FLOW:
// ----------
// 1. Parent widget passes optional ContribuableEntity (null = create mode)
// 2. Form initializes controllers with existing data or empty values
// 3. Reference data loaded async from SQLite database
// 4. User fills/modifies form
// 5. On submit: validation → create entity → callback to parent
// 6. Parent handles database operations (insert/update)
//
// =============================================================================

import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/camera_service.dart';
import '../../core/utils/location_service.dart';
import '../../data/datasources/local/ref_type_activite_local_datasource.dart';
import '../../data/datasources/local/ref_zone_type_local_datasource.dart';
import '../../data/datasources/local/ref_commune_local_datasource.dart';
import '../../data/datasources/local/ref_quartier_local_datasource.dart';
import '../../data/datasources/local/ref_avenue_local_datasource.dart';
import '../../data/models/entities/contribuable_entity.dart';
import '../../data/models/entities/ref_type_activite_entity.dart';
import '../../data/models/entities/ref_zone_type_entity.dart';
import '../../data/models/entities/ref_commune_entity.dart';
import '../../data/models/entities/ref_quartier_entity.dart';
import '../../data/models/entities/ref_avenue_entity.dart';
import '../../data/models/enums/contribuable_enums.dart';
import '../screens/qr_scanner_screen.dart';

// =============================================================================
// MAIN WIDGET CLASS
// =============================================================================

/// Contribuable form for creating and editing taxpayers
/// 
/// This is a StatefulWidget because:
/// - It manages multiple form field states
/// - It has loading states for async operations
/// - It needs to react to user input and update UI accordingly
/// 
/// Parameters:
/// - [contribuable]: Optional existing entity for edit mode (null = create mode)
/// - [onSave]: Callback function called when form is submitted with valid data
/// - [currentUser]: The username of the current logged-in user for audit fields
class ContribuableForm extends StatefulWidget {
  final ContribuableEntity? contribuable;
  final Function(ContribuableEntity) onSave;
  final String currentUser;

  const ContribuableForm({
    super.key,
    this.contribuable,
    required this.onSave,
    required this.currentUser,
  });

  @override
  State<ContribuableForm> createState() => _ContribuableFormState();
}

// =============================================================================
// STATE CLASS - Where all the magic happens
// =============================================================================

class _ContribuableFormState extends State<ContribuableForm> {
  // ---------------------------------------------------------------------------
  // FORM KEY - Used to validate all form fields at once
  // ---------------------------------------------------------------------------
  // GlobalKey<FormState> allows us to:
  // - Validate all form fields with _formKey.currentState!.validate()
  // - Save form field values with _formKey.currentState!.save()
  // - Reset the form with _formKey.currentState!.reset()
  final _formKey = GlobalKey<FormState>();
  
  // ---------------------------------------------------------------------------
  // SERVICE INSTANCES - Utility classes for specific operations
  // ---------------------------------------------------------------------------
  // CameraService: Handles photo capture (camera/gallery) and storage
  // LocationService: Handles GPS location capture with permission management
  final _cameraService = CameraService();
  final _locationService = LocationService();
  
  // ---------------------------------------------------------------------------
  // DATA SOURCE INSTANCES - Access to reference data in SQLite
  // ---------------------------------------------------------------------------
  // These load the dropdown options for activity types and zone types
  final _refTypeActiviteDatasource = RefTypeActiviteLocalDatasource();
  final _refZoneTypeDatasource = RefZoneTypeLocalDatasource();
  final _refCommuneDatasource = RefCommuneLocalDatasource();
  final _refQuartierDatasource = RefQuartierLocalDatasource();
  final _refAvenueDatasource = RefAvenueLocalDatasource();

  // ---------------------------------------------------------------------------
  // TEXT EDITING CONTROLLERS
  // ---------------------------------------------------------------------------
  // Each TextFormField needs a controller to:
  // - Pre-populate values in edit mode
  // - Read values on form submission
  // - Properly dispose resources when widget is destroyed
  // 
  // Using 'late' because they're initialized in initState(), not declaration
  late final TextEditingController _nifController;
  late final TextEditingController _nomController;
  late final TextEditingController _postNomController;
  late final TextEditingController _prenomController;
  late final TextEditingController _raisonSocialeController;
  late final TextEditingController _numeroRccmController;
  late final TextEditingController _telephone1Controller;
  late final TextEditingController _telephone2Controller;
  late final TextEditingController _emailController;
  late final TextEditingController _rueController;
  late final TextEditingController _numeroParcelleController;

  // ---------------------------------------------------------------------------
  // DROPDOWN STATE VARIABLES
  // ---------------------------------------------------------------------------
  // These hold the selected values for dropdown fields
  // Nullable types (?) allow for "no selection" state
  TypeNif? _typeNif;
  TypeContribuable _typeContribuable = TypeContribuable.physique;
  FormeJuridique? _formeJuridique;  // Legal form for legal entities (morale)
  OrigineFiche _origineFiche = OrigineFiche.recensement;
  int? _activiteId;  // Foreign key to ref_type_activite table
  int? _zoneId;      // Foreign key to ref_zone_type table
  int? _communeId;   // Foreign key to ref_commune table
  int? _quartierId;  // Foreign key to ref_quartier table
  int? _avenueId;    // Foreign key to ref_avenue table

  // ---------------------------------------------------------------------------
  // REFERENCE DATA - Loaded from database for dropdowns
  // ---------------------------------------------------------------------------
  List<RefTypeActiviteEntity> _typeActivites = [];
  List<RefZoneTypeEntity> _zoneTypes = [];
  List<RefCommuneEntity> _communes = [];
  List<RefQuartierEntity> _quartiers = [];
  List<RefAvenueEntity> _avenues = [];
  bool _isLoadingActivites = true;  // Show loading indicator while fetching
  bool _isLoadingZones = true;
  bool _isLoadingCommunes = true;
  bool _isLoadingQuartiers = true;
  bool _isLoadingAvenues = true;

  // ---------------------------------------------------------------------------
  // PHOTO & LOCATION DATA
  // ---------------------------------------------------------------------------
  // Photos: List of file paths stored locally on device
  // Location: GPS coordinates (latitude/longitude)
  List<String> _photoPaths = [];
  double? _latitude;
  double? _longitude;

  // ---------------------------------------------------------------------------
  // UI STATE FLAGS
  // ---------------------------------------------------------------------------
  bool _isLoading = false;          // True when submitting form
  bool _isLoadingLocation = false;  // True when capturing GPS location

  // ---------------------------------------------------------------------------
  // COMPUTED PROPERTIES - Derived from other state
  // ---------------------------------------------------------------------------
  // These make the code more readable throughout the widget
  bool get _isEditing => widget.contribuable != null;
  bool get _isPersonneMorale => _typeContribuable == TypeContribuable.morale;

  // ---------------------------------------------------------------------------
  // HELPER METHODS
  // ---------------------------------------------------------------------------
  
  /// Strip +243 prefix from phone number for display in text field
  String _stripPhonePrefix(String? phone) {
    if (phone == null || phone.isEmpty) return '';
    return phone.startsWith('+243') ? phone.substring(4).trim() : phone;
  }

  /// Add +243 prefix to phone number when saving
  String _addPhonePrefix(String phone) {
    final trimmed = phone.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('+243')) return trimmed;
    return '+243$trimmed';
  }

  // ===========================================================================
  // LIFECYCLE METHODS
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    
    // Get existing contribuable (null if creating new)
    final c = widget.contribuable;
    
    // Initialize all text controllers with existing values or empty strings
    // This is where edit mode gets its initial values
    _nifController = TextEditingController(text: c?.nif ?? '');
    _nomController = TextEditingController(text: c?.nom ?? '');
    _postNomController = TextEditingController(text: c?.postNom ?? '');
    _prenomController = TextEditingController(text: c?.prenom ?? '');
    _raisonSocialeController = TextEditingController(text: c?.raisonSociale ?? '');
    _numeroRccmController = TextEditingController(text: c?.numeroRCCM ?? '');
    _telephone1Controller = TextEditingController(text: _stripPhonePrefix(c?.telephone1));
    _telephone2Controller = TextEditingController(text: _stripPhonePrefix(c?.telephone2));
    _emailController = TextEditingController(text: c?.email ?? '');
    _rueController = TextEditingController(text: c?.rue ?? '');
    _numeroParcelleController = TextEditingController(text: c?.numeroParcelle ?? '');

    // Initialize dropdown values
    _typeNif = c?.typeNif;
    _typeContribuable = c?.typeContribuable ?? TypeContribuable.physique;
    _formeJuridique = c?.formeJuridique;
    _origineFiche = c?.origineFiche ?? OrigineFiche.recensement;
    _activiteId = c?.activiteId;
    _zoneId = c?.zoneId;
    _communeId = c?.communeId;
    _quartierId = c?.quartierId;
    _avenueId = c?.avenueId;
    
    // Copy photo paths (List.from creates a new list to avoid reference issues)
    _photoPaths = List.from(c?.pieceIdentiteUrls ?? []);
    
    // Initialize GPS coordinates
    _latitude = c?.gpsLatitude;
    _longitude = c?.gpsLongitude;

    // Load reference data for dropdowns (async)
    _loadReferenceData();
  }

  /// Load all reference data in parallel for better performance
  /// Future.wait executes multiple futures concurrently
  Future<void> _loadReferenceData() async {
    await Future.wait([
      _loadTypeActivites(),
      _loadZoneTypes(),
      _loadCommunes(),
      _loadQuartiers(),
      _loadAvenues(),
    ]);
  }

  /// Load activity types from local database
  Future<void> _loadTypeActivites() async {
    try {
      final activites = await _refTypeActiviteDatasource.getAllTypeActivites();
      if (mounted) {  // Check if widget is still in tree before setState
        setState(() {
          _typeActivites = activites;
          _isLoadingActivites = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingActivites = false);
      }
    }
  }

  /// Load zone types from local database
  Future<void> _loadZoneTypes() async {
    try {
      final zones = await _refZoneTypeDatasource.getAllZoneTypes();
      if (mounted) {
        setState(() {
          _zoneTypes = zones;
          _isLoadingZones = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingZones = false);
      }
    }
  }

  /// Load communes from local database
  Future<void> _loadCommunes() async {
    try {
      final communes = await _refCommuneDatasource.getAllCommunes();
      if (mounted) {
        setState(() {
          _communes = communes;
          _isLoadingCommunes = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCommunes = false);
      }
    }
  }

  /// Load quartiers from local database
  Future<void> _loadQuartiers() async {
    try {
      final quartiers = await _refQuartierDatasource.getAllQuartiers();
      if (mounted) {
        setState(() {
          _quartiers = quartiers;
          _isLoadingQuartiers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingQuartiers = false);
      }
    }
  }

  /// Load avenues from local database
  Future<void> _loadAvenues() async {
    try {
      final avenues = await _refAvenueDatasource.getAllAvenues();
      if (mounted) {
        setState(() {
          _avenues = avenues;
          _isLoadingAvenues = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingAvenues = false);
      }
    }
  }

  @override
  void dispose() {
    // IMPORTANT: Always dispose TextEditingControllers to prevent memory leaks
    // Each controller holds resources that must be released
    _nifController.dispose();
    _nomController.dispose();
    _postNomController.dispose();
    _prenomController.dispose();
    _raisonSocialeController.dispose();
    _numeroRccmController.dispose();
    _telephone1Controller.dispose();
    _telephone2Controller.dispose();
    _emailController.dispose();
    _rueController.dispose();
    _numeroParcelleController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // PHOTO HANDLING METHODS
  // ===========================================================================

  /// Shows a bottom sheet letting user choose between camera and gallery
  /// 
  /// Bottom sheets are great for presenting a small set of options
  /// They slide up from the bottom and can be dismissed by tapping outside
  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        // SafeArea prevents content from going under system UI (notch, home bar)
        child: Wrap(
          // Wrap sizes itself to fit its children
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Prendre une Photo'),
              onTap: () {
                Navigator.pop(context);  // Close bottom sheet first
                _takePhoto();            // Then trigger camera
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choisir de la Galerie'),
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Capture a photo using the device camera
  /// 
  /// Uses CameraService which handles:
  /// - Opening the camera
  /// - Capturing the image
  /// - Compressing/resizing for storage optimization
  /// - Saving to app's documents directory
  /// - Returning the file path
  Future<void> _takePhoto() async {
    final path = await _cameraService.takePhoto();
    if (path != null && mounted) {
      // Add the new photo path to our list
      setState(() => _photoPaths.add(path));
    }
  }

  /// Pick an image from the device gallery
  Future<void> _pickFromGallery() async {
    final path = await _cameraService.pickFromGallery();
    if (path != null && mounted) {
      setState(() => _photoPaths.add(path));
    }
  }

  /// Remove a photo from the list (does not delete from disk here)
  /// The actual file deletion happens when the contribuable is deleted
  void _removePhoto(int index) {
    setState(() => _photoPaths.removeAt(index));
  }

  /// Navigate to full-screen photo viewer
  /// Uses a separate page for better UX with pinch-to-zoom
  void _viewPhoto(String photoPath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _PhotoViewPage(photoPath: photoPath),
      ),
    );
  }

  // ===========================================================================
  // GPS LOCATION METHODS
  // ===========================================================================

  /// Capture current GPS location
  /// 
  /// This method:
  /// 1. Shows loading indicator
  /// 2. Requests location permission if needed
  /// 3. Gets current position from GPS
  /// 4. Updates state with coordinates
  /// 5. Shows success/error feedback
  Future<void> _captureLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      final position = await _locationService.getCurrentPosition();

      if (position != null && mounted) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
        });
        // Show success feedback with SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Position GPS capturée!')),
        );
      } else if (mounted) {
        // Position null usually means permission denied
        _showLocationPermissionDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur GPS: $e')),
        );
      }
    } finally {
      // Always hide loading indicator, even on error
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  /// Clear the captured location
  void _removeLocation() {
    setState(() {
      _latitude = null;
      _longitude = null;
    });
  }

  /// Show dialog explaining location permission is required
  /// Offers a button to open app settings for manual permission grant
  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission de Localisation Requise'),
        content: const Text(
          'Veuillez activer les services de localisation et accorder la permission.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _locationService.openAppSettings();  // Open system settings
            },
            child: const Text('Paramètres'),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // FORM SUBMISSION
  // ===========================================================================

  /// Handle form submission
  /// 
  /// This is the main submit handler that:
  /// 1. Validates all form fields
  /// 2. Creates a ContribuableEntity from form data
  /// 3. Calls the parent's onSave callback
  /// 
  /// The parent widget handles the actual database operation
  Future<void> _onSubmit() async {
    // Validate all form fields - returns false if any validation fails
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Create the entity from form data
      // Note how we handle edit vs create mode for various fields
      final contribuable = ContribuableEntity(
        // Keep existing ID for updates, null for new records
        id: widget.contribuable?.id,
        
        // NIF and type - only set if not empty
        nif: _nifController.text.trim().isEmpty ? null : _nifController.text.trim(),
        typeNif: _typeNif,
        typeContribuable: _typeContribuable,
        
        // Name fields depend on taxpayer type (person vs company)
        nom: _isPersonneMorale ? null : _nomController.text.trim(),
        postNom: _isPersonneMorale ? null : _postNomController.text.trim(),
        prenom: _isPersonneMorale ? null : _prenomController.text.trim(),
        raisonSociale: _isPersonneMorale ? _raisonSocialeController.text.trim() : null,
        formeJuridique: _isPersonneMorale ? _formeJuridique : null,
        numeroRCCM: _isPersonneMorale && _numeroRccmController.text.trim().isNotEmpty ? _numeroRccmController.text.trim() : null,
        
        // Contact information
        telephone1: _addPhonePrefix(_telephone1Controller.text),
        telephone2: _telephone2Controller.text.trim().isEmpty ? null : _addPhonePrefix(_telephone2Controller.text),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        communeId: _communeId,
        quartierId: _quartierId,
        avenueId: _avenueId,
        rue: _rueController.text.trim().isEmpty ? null : _rueController.text.trim(),
        numeroParcelle: _numeroParcelleController.text.trim().isEmpty ? null : _numeroParcelleController.text.trim(),
        
        // Classification
        origineFiche: _origineFiche,
        activiteId: _activiteId,
        zoneId: _zoneId,
        statut: widget.contribuable?.statut ?? 1,  // Default status: active
        
        // GPS coordinates
        gpsLatitude: _latitude,
        gpsLongitude: _longitude,
        
        // Photo file paths (stored as JSON array in database)
        pieceIdentiteUrls: _photoPaths,
        
        // Audit fields
        dateInscription: widget.contribuable?.dateInscription ?? DateTime.now(),
        createdAt: widget.contribuable?.createdAt,  // Keep original for edits
        creePar: widget.contribuable?.creePar ?? widget.currentUser,
        dateMaj: _isEditing ? DateTime.now() : null,  // Set only on update
        majPar: _isEditing ? widget.currentUser : null,
        updatedAt: DateTime.now(),
      );

      // Call parent's callback - parent handles database operation
      widget.onSave(contribuable);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ===========================================================================
  // BUILD METHOD - Main UI Construction
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    // Scaffold provides the basic page structure with AppBar
    return Scaffold(
      appBar: AppBar(
        // Dynamic title based on mode (create vs edit)
        title: Text(_isEditing ? 'Modifier Contribuable' : 'Nouveau Contribuable'),
      ),
      // SingleChildScrollView allows the form to scroll when keyboard appears
      // or when content exceeds screen height
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        // Form widget groups all form fields and enables validation
        child: Form(
          key: _formKey,  // Connects form to our GlobalKey for validation
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ---------------------------------------------------------
              // PHOTOS SECTION - ID document photos
              // ---------------------------------------------------------
              _buildPhotosSection(),
              const SizedBox(height: 24),

              // ---------------------------------------------------------
              // TYPE CONTRIBUABLE - Physical person or Legal entity
              // ---------------------------------------------------------
              _buildSectionTitle('Type de Contribuable'),
              const SizedBox(height: 8),
              // DropdownButtonFormField integrates with Form validation
              DropdownButtonFormField<TypeContribuable>(
                value: _typeContribuable,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.category),
                ),
                // Generate dropdown items from enum values
                items: TypeContribuable.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    // Changing type will show/hide different form fields
                    setState(() {
                      _typeContribuable = value;
                      // Reset forme juridique when switching away from morale
                      if (value != TypeContribuable.morale) {
                        _formeJuridique = null;
                      }
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // ---------------------------------------------------------
              // NIF SECTION - Tax identification number
              // ---------------------------------------------------------
              _buildSectionTitle('Identification Fiscale'),
              const SizedBox(height: 8),
              // Row allows placing NIF and Type side by side
              Row(
                children: [
                  // flex: 2 makes this take 2/3 of the available width
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _nifController,
                      decoration: InputDecoration(
                        labelText: 'NIF',
                        prefixIcon: const Icon(Icons.badge),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.qr_code_scanner),
                          tooltip: 'Scanner QR Code',
                          onPressed: () async {
                            final scannedValue = await Navigator.push<String>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const QrScannerScreen(),
                              ),
                            );
                            if (scannedValue != null && mounted) {
                              setState(() {
                                _nifController.text = scannedValue;
                              });
                            }
                          },
                        ),
                      ),
                      // No validator - NIF is optional
                    ),
                  ),
                  const SizedBox(width: 12),
                  // flex: 1 (default) makes this take 1/3 of width
                  Expanded(
                    child: DropdownButtonFormField<TypeNif>(
                      value: _typeNif,
                      isExpanded: true,  // Prevents overflow in small spaces
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        // Allow null selection (no type)
                        const DropdownMenuItem(
                          value: null,
                          child: Text('-'),
                        ),
                        // Add all enum values
                        ...TypeNif.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type.value, overflow: TextOverflow.ellipsis),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() => _typeNif = value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ---------------------------------------------------------
              // IDENTITY SECTION - Conditional based on taxpayer type
              // ---------------------------------------------------------
              // This demonstrates conditional rendering in Flutter
              // Different fields shown for person vs company
              if (_isPersonneMorale) ...[
                // LEGAL ENTITY (Company) - Show company name field
                _buildSectionTitle('Raison Sociale'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _raisonSocialeController,
                  decoration: const InputDecoration(
                    labelText: 'Raison Sociale *',
                    prefixIcon: Icon(Icons.business),
                  ),
                  textCapitalization: TextCapitalization.words,
                  // Custom validator from our Validators utility class
                  validator: (value) =>
                      Validators.required(value, fieldName: 'Raison sociale'),
                ),
                const SizedBox(height: 16),
                
                // FORME JURIDIQUE - Legal form dropdown
                _buildSectionTitle('Forme Juridique'),
                const SizedBox(height: 8),
                DropdownButtonFormField<FormeJuridique>(
                  value: _formeJuridique,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Forme Juridique',
                    prefixIcon: Icon(Icons.account_balance),
                    hintText: 'Sélectionner une forme juridique',
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('-'),
                    ),
                    ...FormeJuridique.values.map((forme) {
                      return DropdownMenuItem(
                        value: forme,
                        child: Text(forme.displayName),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() => _formeJuridique = value);
                  },
                ),
                const SizedBox(height: 16),
                
                // RCCM NUMBER
                _buildSectionTitle('Numéro RCCM'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _numeroRccmController,
                  decoration: const InputDecoration(
                    labelText: 'Numéro RCCM',
                    prefixIcon: Icon(Icons.numbers),
                    hintText: 'Ex: CD/KIN/RCCM/XX-X-XXXXX',
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
              ] else ...[
                // PHYSICAL PERSON - Show name fields (nom, postnom, prenom)
                _buildSectionTitle('Identité'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nomController,
                  decoration: const InputDecoration(
                    labelText: 'Nom *',
                    prefixIcon: Icon(Icons.person),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) =>
                      Validators.required(value, fieldName: 'Nom'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _postNomController,
                  decoration: const InputDecoration(
                    labelText: 'Post-nom',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  textCapitalization: TextCapitalization.words,
                  // No validator - optional field
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _prenomController,
                  decoration: const InputDecoration(
                    labelText: 'Prénom',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
              ],
              const SizedBox(height: 24),

              // ---------------------------------------------------------
              // CONTACT SECTION - Phone numbers and email
              // ---------------------------------------------------------
              _buildSectionTitle('Contact'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _telephone1Controller,
                decoration: const InputDecoration(
                  labelText: 'Téléphone 1 *',
                  prefixIcon: Icon(Icons.phone),
                  prefixText: '+243 ',
                ),
                keyboardType: TextInputType.phone,  // Shows phone keyboard
                validator: (value) =>
                    Validators.required(value, fieldName: 'Téléphone'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _telephone2Controller,
                decoration: const InputDecoration(
                  labelText: 'Téléphone 2',
                  prefixIcon: Icon(Icons.phone_android),
                  prefixText: '+243 ',
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                // Email validation only if not empty
                validator: (value) {
                  if (value == null || value.isEmpty) return null;
                  return Validators.email(value);
                },
              ),
              const SizedBox(height: 24),

              // ---------------------------------------------------------
              // ADDRESS SECTION - 5 fields: Commune, Quartier, Avenue (dropdowns) + Rue, Numéro de parcelle (text)
              // ---------------------------------------------------------
              _buildSectionTitle('Adresse'),
              const SizedBox(height: 8),

              // Commune dropdown
              _isLoadingCommunes
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<int>(
                      value: _communeId,
                      decoration: const InputDecoration(
                        labelText: 'Commune',
                        prefixIcon: Icon(Icons.location_city),
                        hintText: 'Sélectionner une commune',
                      ),
                      items: [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text('-- Aucune --'),
                        ),
                        ..._communes.map((commune) {
                          return DropdownMenuItem<int>(
                            value: commune.id,
                            child: Text(commune.libelle),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() => _communeId = value);
                      },
                    ),
              const SizedBox(height: 12),

              // Quartier dropdown
              _isLoadingQuartiers
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<int>(
                      value: _quartierId,
                      decoration: const InputDecoration(
                        labelText: 'Quartier',
                        prefixIcon: Icon(Icons.holiday_village),
                        hintText: 'Sélectionner un quartier',
                      ),
                      items: [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text('-- Aucun --'),
                        ),
                        ..._quartiers.map((quartier) {
                          return DropdownMenuItem<int>(
                            value: quartier.id,
                            child: Text(quartier.libelle),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() => _quartierId = value);
                      },
                    ),
              const SizedBox(height: 12),

              // Avenue dropdown
              _isLoadingAvenues
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<int>(
                      value: _avenueId,
                      decoration: const InputDecoration(
                        labelText: 'Avenue',
                        prefixIcon: Icon(Icons.signpost),
                        hintText: 'Sélectionner une avenue',
                      ),
                      items: [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text('-- Aucune --'),
                        ),
                        ..._avenues.map((avenue) {
                          return DropdownMenuItem<int>(
                            value: avenue.id,
                            child: Text(avenue.libelle),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() => _avenueId = value);
                      },
                    ),
              const SizedBox(height: 12),

              // Rue text field
              TextFormField(
                controller: _rueController,
                decoration: const InputDecoration(
                  labelText: 'Rue',
                  prefixIcon: Icon(Icons.edit_road),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),

              // Numéro de parcelle text field
              TextFormField(
                controller: _numeroParcelleController,
                decoration: const InputDecoration(
                  labelText: 'Numéro de parcelle',
                  prefixIcon: Icon(Icons.home),
                ),
              ),
              const SizedBox(height: 24),

              // ---------------------------------------------------------
              // ACTIVITY TYPE SECTION - Dropdown from database
              // ---------------------------------------------------------
              _buildSectionTitle('Type d\'Activité'),
              const SizedBox(height: 8),
              // Show loading indicator while data loads
              _isLoadingActivites
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<int>(
                      value: _activiteId,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.work),
                        hintText: 'Sélectionner une activité',
                      ),
                      items: [
                        // First item: no selection
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text('-- Aucune --'),
                        ),
                        // Dynamically loaded items from database
                        ..._typeActivites.map((activite) {
                          return DropdownMenuItem<int>(
                            value: activite.id,
                            child: Text(activite.libelle),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() => _activiteId = value);
                      },
                    ),
              const SizedBox(height: 24),

              // ---------------------------------------------------------
              // ZONE TYPE SECTION - Dropdown from database
              // ---------------------------------------------------------
              _buildSectionTitle('Type de Zone'),
              const SizedBox(height: 8),
              _isLoadingZones
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<int>(
                      value: _zoneId,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.map),
                        hintText: 'Sélectionner une zone',
                      ),
                      items: [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text('-- Aucune --'),
                        ),
                        ..._zoneTypes.map((zone) {
                          return DropdownMenuItem<int>(
                            value: zone.id,
                            child: Text(zone.libelle),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() => _zoneId = value);
                      },
                    ),
              const SizedBox(height: 24),

              // ---------------------------------------------------------
              // GPS LOCATION SECTION - Custom widget for location capture
              // ---------------------------------------------------------
              _buildLocationSection(),
              const SizedBox(height: 24),

              // ---------------------------------------------------------
              // ORIGIN FIELD - How this record was created
              // ---------------------------------------------------------
              _buildSectionTitle('Origine de la Fiche'),
              const SizedBox(height: 8),
              DropdownButtonFormField<OrigineFiche>(
                value: _origineFiche,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.source),
                ),
                items: OrigineFiche.values.map((origine) {
                  return DropdownMenuItem(
                    value: origine,
                    child: Text(origine.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _origineFiche = value);
                  }
                },
              ),
              const SizedBox(height: 32),

              // ---------------------------------------------------------
              // SUBMIT BUTTON
              // ---------------------------------------------------------
              ElevatedButton(
                // Disable button while loading to prevent double-submission
                onPressed: _isLoading ? null : _onSubmit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                // Show loading spinner or text based on state
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _isEditing ? 'Mettre à jour' : 'Enregistrer',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // HELPER WIDGETS - Reusable UI Components
  // ===========================================================================

  /// Build a styled section title
  /// Extracted to a method to maintain consistent styling across sections
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  // ===========================================================================
  // PHOTOS SECTION WIDGET
  // ===========================================================================

  /// Build the photos section with add/view/remove functionality
  /// 
  /// This demonstrates:
  /// - Horizontal scrolling list
  /// - Conditional rendering (empty state vs photos)
  /// - Image display from local file system
  Widget _buildPhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row with title and add button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Show count of photos in title
            _buildSectionTitle('Pièce d\'Identité (${_photoPaths.length})'),
            TextButton.icon(
              onPressed: _showImageSourceOptions,
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Ajouter'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Conditional: Show empty state or photo list
        if (_photoPaths.isEmpty)
          // EMPTY STATE - Placeholder when no photos added
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    'Ajouter une photo de la pièce d\'identité',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          )
        else
          // PHOTO LIST - Horizontal scrolling list of photos
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,  // Horizontal scroll
              // +1 to include "Add" button at the end
              itemCount: _photoPaths.length + 1,
              itemBuilder: (context, index) {
                // Last item is the "Add" button
                if (index == _photoPaths.length) {
                  return _buildAddPhotoButton();
                }
                // Regular photo item
                return _buildPhotoItem(index);
              },
            ),
          ),
      ],
    );
  }

  /// Build a single photo item with delete button overlay
  /// 
  /// Uses Stack to overlay the delete button on top of the image
  Widget _buildPhotoItem(int index) {
    final photoPath = _photoPaths[index];
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          // The photo - tappable to view full screen
          GestureDetector(
            onTap: () => _viewPhoto(photoPath),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              // Image.file loads image from local file system
              child: Image.file(
                File(photoPath),
                width: 100,
                height: 120,
                fit: BoxFit.cover,  // Crop to fill container
              ),
            ),
          ),
          // Delete button - positioned in top-right corner
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removePhoto(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build the "Add Photo" button shown at the end of photo list
  Widget _buildAddPhotoButton() {
    return GestureDetector(
      onTap: _showImageSourceOptions,
      child: Container(
        width: 100,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 32, color: Colors.grey.shade600),
            const SizedBox(height: 4),
            Text('Ajouter', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // GPS LOCATION SECTION WIDGET
  // ===========================================================================

  /// Build the GPS location section with capture/remove functionality
  /// 
  /// Shows different UI based on whether location is captured or not
  Widget _buildLocationSection() {
    // Computed property for cleaner conditionals
    final hasLocation = _latitude != null && _longitude != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Position GPS'),
        const SizedBox(height: 8),
        // Container with visual styling
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              // Location icon - changes color based on state
              Icon(
                hasLocation ? Icons.location_on : Icons.location_off,
                size: 32,
                color: hasLocation ? Colors.green : Colors.grey.shade400,
              ),
              const SizedBox(width: 12),
              // Location info text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasLocation ? 'Position capturée' : 'Aucune position',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: hasLocation ? Colors.green : Colors.grey.shade600,
                      ),
                    ),
                    // Show coordinates if captured
                    if (hasLocation)
                      Text(
                        // toStringAsFixed(6) gives 6 decimal places precision
                        '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                  ],
                ),
              ),
              // Action buttons - either loading spinner or icon buttons
              if (_isLoadingLocation)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Capture button - always visible
                    IconButton(
                      icon: Icon(Icons.my_location, color: Theme.of(context).primaryColor),
                      tooltip: 'Capturer la position',
                      onPressed: _captureLocation,
                    ),
                    // Remove button - only visible when location exists
                    if (hasLocation)
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        tooltip: 'Supprimer la position',
                        onPressed: _removeLocation,
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// PHOTO VIEWER PAGE - Full-screen image viewer
// =============================================================================

/// Full screen photo viewer with pinch-to-zoom
/// 
/// This is a separate widget (private class with underscore prefix)
/// Uses InteractiveViewer for pan and zoom functionality
class _PhotoViewPage extends StatelessWidget {
  final String photoPath;

  const _PhotoViewPage({required this.photoPath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,  // Dark background for photo viewing
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        // InteractiveViewer provides built-in pan and zoom
        child: InteractiveViewer(
          panEnabled: true,     // Allow panning/dragging
          minScale: 0.5,        // Can zoom out to 50%
          maxScale: 4,          // Can zoom in to 400%
          child: Image.file(File(photoPath), fit: BoxFit.contain),
        ),
      ),
    );
  }
}
