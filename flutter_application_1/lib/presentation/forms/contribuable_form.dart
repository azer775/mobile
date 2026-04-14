import 'package:flutter/material.dart';
import '../../core/utils/validators.dart';
import '../../data/models/entities/contribuable_entity.dart';
import '../../data/models/enums/parcelle_enums.dart';
import '../screens/qr_scanner_screen.dart';

/// Contribuable form for creating and editing contribuables
/// 
/// This form is used within the ImmobilierWizard as Step 2.
/// It can also be used standalone for editing existing contribuables.
class ContribuableForm extends StatefulWidget {
  final ContribuableEntity? contribuable;
  final int? parcelleId;
  final Function(ContribuableEntity) onSave;
  final bool showAppBar;

  const ContribuableForm({
    super.key,
    this.contribuable,
    this.parcelleId,
    required this.onSave,
    this.showAppBar = true,
  });

  @override
  State<ContribuableForm> createState() => ContribuableFormState();
}

class ContribuableFormState extends State<ContribuableForm> {
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  late final TextEditingController _nomController;
  late final TextEditingController _prenomController;
  late final TextEditingController _pieceIdentiteController;
  late final TextEditingController _nomRaisonSocialeController;
  late final TextEditingController _nifController;
  late final TextEditingController _contactController;
  late final TextEditingController _emailController;
  late final TextEditingController _adressePostaleController;

  // Dropdown values
  TypeContribuable _typeContribuable = TypeContribuable.physique;

  // UI state
  bool _isLoading = false;

  bool get _isEditing => widget.contribuable != null;
  bool get _isMorale => _typeContribuable == TypeContribuable.morale;

  /// Strip +243 prefix from phone number for display in text field
  String _stripPhonePrefix(String? phone) {
    if (phone == null || phone.isEmpty) return '';
    return phone.startsWith('+243') ? phone.substring(4).trim() : phone;
  }

  /// Add +243 prefix to phone number when saving
  String _addPhonePrefix(String contact) {
    final trimmed = contact.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('+')) return trimmed;
    return '+243$trimmed';
  }

  @override
  void initState() {
    super.initState();
    final p = widget.contribuable;

    _nomController = TextEditingController(text: p?.nom ?? '');
    _prenomController = TextEditingController(text: p?.prenom ?? '');
    _pieceIdentiteController = TextEditingController(text: p?.pieceIdentite ?? '');
    _nomRaisonSocialeController = TextEditingController(text: p?.nomRaisonSociale ?? '');
    _nifController = TextEditingController(text: p?.nif ?? '');
    _contactController = TextEditingController(text: _stripPhonePrefix(p?.contact));
    _emailController = TextEditingController(text: p?.email ?? '');
    _adressePostaleController = TextEditingController(text: p?.adressePostale ?? '');

    _typeContribuable = p?.typeContribuable ?? TypeContribuable.physique;
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _pieceIdentiteController.dispose();
    _nomRaisonSocialeController.dispose();
    _nifController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _adressePostaleController.dispose();
    super.dispose();
  }

  /// Public method to validate the form (called from wizard)
  bool validate() {
    return _formKey.currentState?.validate() ?? false;
  }

  /// Public method to get the current contribuable data
  ContribuableEntity getData() {
    return ContribuableEntity(
      id: widget.contribuable?.id,
      typeContribuable: _typeContribuable,
      nom: _nomController.text.trim().isEmpty
          ? null : _nomController.text.trim(),
      prenom: _prenomController.text.trim().isEmpty
          ? null : _prenomController.text.trim(),
      pieceIdentite: _pieceIdentiteController.text.trim().isEmpty
          ? null : _pieceIdentiteController.text.trim(),
      nomRaisonSociale: _nomRaisonSocialeController.text.trim().isEmpty 
          ? null : _nomRaisonSocialeController.text.trim(),
      nif: _nifController.text.trim().isEmpty 
          ? null : _nifController.text.trim(),
      contact: _contactController.text.trim().isEmpty 
          ? null : _addPhonePrefix(_contactController.text),
      email: _emailController.text.trim().isEmpty 
          ? null : _emailController.text.trim(),
      adressePostale: _adressePostaleController.text.trim().isEmpty 
          ? null : _adressePostaleController.text.trim(),
      parcelleId: widget.parcelleId ?? widget.contribuable?.parcelleId,
      createdAt: widget.contribuable?.createdAt,
      updatedAt: DateTime.now(),
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
            // TYPE DE CONTRIBUABLE
            _buildSectionTitle('Type de Contribuable'),
            const SizedBox(height: 8),
            DropdownButtonFormField<TypeContribuable>(
              value: _typeContribuable,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.person_pin),
              ),
              items: TypeContribuable.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.value.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _typeContribuable = value);
                }
              },
            ),
            const SizedBox(height: 24),

            // IDENTITÉ
            if (_isMorale) ...[              _buildSectionTitle('Raison Sociale'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nomRaisonSocialeController,
                decoration: const InputDecoration(
                  labelText: 'Raison Sociale *',
                  prefixIcon: Icon(Icons.business),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) =>
                    Validators.required(value, fieldName: 'Raison sociale'),
              ),
            ] else ...[              _buildSectionTitle('Identité'),
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
                controller: _prenomController,
                decoration: const InputDecoration(
                  labelText: 'Prénom',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pieceIdentiteController,
                decoration: const InputDecoration(
                  labelText: "Pièce d'identité",
                  prefixIcon: Icon(Icons.credit_card),
                ),
              ),
            ],
            const SizedBox(height: 24),

            // NIF
            _buildSectionTitle('Identification Fiscale'),
            const SizedBox(height: 8),
            TextFormField(
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
            ),
            const SizedBox(height: 24),

            // CONTACT
            _buildSectionTitle('Contact'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _contactController,
              decoration: const InputDecoration(
                labelText: 'Téléphone',
                prefixIcon: Icon(Icons.phone),
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
                hintText: 'exemple@mail.com',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _adressePostaleController,
              decoration: const InputDecoration(
                labelText: 'Adresse Postale',
                prefixIcon: Icon(Icons.mail),
              ),
              maxLines: 2,
            ),
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
        title: Text(_isEditing ? 'Modifier Propriétaire' : 'Nouveau Propriétaire'),
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
}
