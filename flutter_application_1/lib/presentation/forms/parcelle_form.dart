import 'package:flutter/material.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/location_service.dart';
import '../../data/datasources/local/ref_commune_local_datasource.dart';
import '../../data/datasources/local/ref_quartier_local_datasource.dart';
import '../../data/datasources/local/ref_avenue_local_datasource.dart';
import '../../data/models/entities/parcelle_entity.dart';
import '../../data/models/entities/ref_commune_entity.dart';
import '../../data/models/entities/ref_quartier_entity.dart';
import '../../data/models/entities/ref_avenue_entity.dart';
import '../../data/models/enums/parcelle_enums.dart';

/// Parcelle form for creating and editing parcelles
/// 
/// This form is used within the ImmobilierWizard as Step 1.
/// It can also be used standalone for editing existing parcelles.
class ParcelleForm extends StatefulWidget {
  final ParcelleEntity? parcelle;
  final Function(ParcelleEntity) onSave;
  final bool showAppBar;
  final bool autoSubmit;

  const ParcelleForm({
    super.key,
    this.parcelle,
    required this.onSave,
    this.showAppBar = true,
    this.autoSubmit = false,
  });

  @override
  State<ParcelleForm> createState() => ParcelleFormState();
}

class ParcelleFormState extends State<ParcelleForm> {
  final _formKey = GlobalKey<FormState>();
  final _locationService = LocationService();

  // Data source instances for reference dropdowns
  final _refCommuneDatasource = RefCommuneLocalDatasource();
  final _refQuartierDatasource = RefQuartierLocalDatasource();
  final _refAvenueDatasource = RefAvenueLocalDatasource();

  // Text controllers
  late final TextEditingController _codeParcelleController;
  late final TextEditingController _referenceCadastraleController;
  late final TextEditingController _rueController;
  late final TextEditingController _numeroParcelleController;
  late final TextEditingController _superficieController;

  // Dropdown values
  StatutParcelle _statutParcelle = StatutParcelle.active;

  // Address dropdown selections (FK IDs, matching contribuable pattern)
  int? _communeId;
  int? _quartierId;
  int? _avenueId;

  // Reference data lists
  List<RefCommuneEntity> _communes = [];
  List<RefQuartierEntity> _quartiers = [];
  List<RefAvenueEntity> _avenues = [];
  bool _isLoadingCommunes = true;
  bool _isLoadingQuartiers = true;
  bool _isLoadingAvenues = true;

  // GPS coordinates
  double? _latitude;
  double? _longitude;

  // UI state
  bool _isLoading = false;
  bool _isLoadingLocation = false;

  bool get _isEditing => widget.parcelle != null;

  @override
  void initState() {
    super.initState();
    final p = widget.parcelle;

    _codeParcelleController = TextEditingController(text: p?.codeParcelle ?? '');
    _referenceCadastraleController = TextEditingController(text: p?.referenceCadastrale ?? '');
    _rueController = TextEditingController(text: p?.rue ?? '');
    _numeroParcelleController = TextEditingController(text: p?.numeroParcelle ?? '');
    _superficieController = TextEditingController(
      text: p?.superficieM2?.toString() ?? '',
    );

    _statutParcelle = p?.statutParcelle ?? StatutParcelle.active;
    _communeId = p?.communeId;
    _quartierId = p?.quartierId;
    _avenueId = p?.avenueId;
    _latitude = p?.gpsLat;
    _longitude = p?.gpsLon;

    _loadReferenceData();
  }

  /// Load all reference data in parallel
  Future<void> _loadReferenceData() async {
    await Future.wait([
      _loadCommunes(),
      _loadQuartiers(),
      _loadAvenues(),
    ]);
  }

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
    _codeParcelleController.dispose();
    _referenceCadastraleController.dispose();
    _rueController.dispose();
    _numeroParcelleController.dispose();
    _superficieController.dispose();
    super.dispose();
  }

  /// Public method to validate the form (called from wizard)
  bool validate() {
    return _formKey.currentState?.validate() ?? false;
  }

  /// Public method to get the current parcelle data
  ParcelleEntity getData() {
    return ParcelleEntity(
      id: widget.parcelle?.id,
      codeParcelle: _codeParcelleController.text.trim().isEmpty 
          ? null : _codeParcelleController.text.trim(),
      referenceCadastrale: _referenceCadastraleController.text.trim().isEmpty 
          ? null : _referenceCadastraleController.text.trim(),
      communeId: _communeId,
      quartierId: _quartierId,
      avenueId: _avenueId,
      rue: _rueController.text.trim().isEmpty
          ? null : _rueController.text.trim(),
      numeroParcelle: _numeroParcelleController.text.trim().isEmpty
          ? null : _numeroParcelleController.text.trim(),
      superficieM2: _superficieController.text.trim().isEmpty 
          ? null : double.tryParse(_superficieController.text.trim()),
      gpsLat: _latitude,
      gpsLon: _longitude,
      statutParcelle: _statutParcelle,
      dateCreation: widget.parcelle?.dateCreation ?? DateTime.now(),
      dateMiseAJour: _isEditing ? DateTime.now() : null,
      sourceDonnee: widget.parcelle?.sourceDonnee ?? 'Application mobile',
      createdAt: widget.parcelle?.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _captureLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      final position = await _locationService.getCurrentPosition();

      if (position != null && mounted) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Position GPS capturée!')),
        );
      } else if (mounted) {
        _showLocationPermissionDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur GPS: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  void _removeLocation() {
    setState(() {
      _latitude = null;
      _longitude = null;
    });
  }

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
              _locationService.openAppSettings();
            },
            child: const Text('Paramètres'),
          ),
        ],
      ),
    );
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      widget.onSave(getData());
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

  @override
  Widget build(BuildContext context) {
    final refsLoaded =
        !_isLoadingCommunes && !_isLoadingQuartiers && !_isLoadingAvenues;
    final hasMissingRefs =
        _communes.isEmpty || _quartiers.isEmpty || _avenues.isEmpty;

    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (refsLoaded && hasMissingRefs) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Les données de référence sont incomplètes. '
                        'Veuillez synchroniser les références depuis le serveur '
                        'via le menu utilisateur sur la page d\'accueil.',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // IDENTIFICATION SECTION
            _buildSectionTitle('Identification de la Parcelle'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _codeParcelleController,
              decoration: const InputDecoration(
                labelText: 'Code Parcelle',
                prefixIcon: Icon(Icons.tag),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _referenceCadastraleController,
              decoration: const InputDecoration(
                labelText: 'Référence Cadastrale',
                prefixIcon: Icon(Icons.article),
              ),
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

            // CARACTÉRISTIQUES SECTION
            _buildSectionTitle('Caractéristiques'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _superficieController,
              decoration: const InputDecoration(
                labelText: 'Superficie (m²)',
                prefixIcon: Icon(Icons.square_foot),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<StatutParcelle>(
              value: _statutParcelle,
              decoration: const InputDecoration(
                labelText: 'Statut de la Parcelle *',
                prefixIcon: Icon(Icons.flag),
              ),
              items: StatutParcelle.values.map((statut) {
                return DropdownMenuItem(
                  value: statut,
                  child: Text(statut.value),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _statutParcelle = value);
                }
              },
            ),
            const SizedBox(height: 24),

            // GPS LOCATION SECTION
            _buildLocationSection(),
            const SizedBox(height: 32),

            // SUBMIT BUTTON (only if showAppBar is true, i.e., standalone mode)
            if (widget.showAppBar)
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
                        _isEditing ? 'Mettre à jour' : 'Enregistrer',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (!widget.showAppBar) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier Parcelle' : 'Nouvelle Parcelle'),
      ),
      body: content,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildLocationSection() {
    final hasLocation = _latitude != null && _longitude != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Position GPS'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Icon(
                hasLocation ? Icons.location_on : Icons.location_off,
                size: 32,
                color: hasLocation ? Colors.green : Colors.grey.shade400,
              ),
              const SizedBox(width: 12),
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
                    if (hasLocation)
                      Text(
                        '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                  ],
                ),
              ),
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
                    IconButton(
                      icon: Icon(Icons.my_location, color: Theme.of(context).primaryColor),
                      tooltip: 'Capturer la position',
                      onPressed: _captureLocation,
                    ),
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
