import 'package:flutter/material.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/location_service.dart';
import '../../data/models/entities/parcelle_entity.dart';
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

  // Text controllers
  late final TextEditingController _codeParcelleController;
  late final TextEditingController _referenceCadastraleController;
  late final TextEditingController _communeController;
  late final TextEditingController _quartierController;
  late final TextEditingController _rueAvenueController;
  late final TextEditingController _numeroAdresseController;
  late final TextEditingController _superficieController;

  // Dropdown values
  StatutParcelle _statutParcelle = StatutParcelle.active;

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
    _communeController = TextEditingController(text: p?.commune ?? '');
    _quartierController = TextEditingController(text: p?.quartier ?? '');
    _rueAvenueController = TextEditingController(text: p?.rueAvenue ?? '');
    _numeroAdresseController = TextEditingController(text: p?.numeroAdresse ?? '');
    _superficieController = TextEditingController(
      text: p?.superficieM2?.toString() ?? '',
    );

    _statutParcelle = p?.statutParcelle ?? StatutParcelle.active;
    _latitude = p?.gpsLat;
    _longitude = p?.gpsLon;
  }

  @override
  void dispose() {
    _codeParcelleController.dispose();
    _referenceCadastraleController.dispose();
    _communeController.dispose();
    _quartierController.dispose();
    _rueAvenueController.dispose();
    _numeroAdresseController.dispose();
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
      commune: _communeController.text.trim().isEmpty 
          ? null : _communeController.text.trim(),
      quartier: _quartierController.text.trim().isEmpty 
          ? null : _quartierController.text.trim(),
      rueAvenue: _rueAvenueController.text.trim().isEmpty 
          ? null : _rueAvenueController.text.trim(),
      numeroAdresse: _numeroAdresseController.text.trim().isEmpty 
          ? null : _numeroAdresseController.text.trim(),
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
    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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

            // LOCALISATION SECTION
            _buildSectionTitle('Localisation'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _communeController,
              decoration: const InputDecoration(
                labelText: 'Commune *',
                prefixIcon: Icon(Icons.location_city),
              ),
              validator: (value) =>
                  Validators.required(value, fieldName: 'Commune'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _quartierController,
              decoration: const InputDecoration(
                labelText: 'Quartier *',
                prefixIcon: Icon(Icons.holiday_village),
              ),
              validator: (value) =>
                  Validators.required(value, fieldName: 'Quartier'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _rueAvenueController,
                    decoration: const InputDecoration(
                      labelText: 'Rue/Avenue',
                      prefixIcon: Icon(Icons.signpost),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _numeroAdresseController,
                    decoration: const InputDecoration(
                      labelText: 'N°',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
              ],
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
