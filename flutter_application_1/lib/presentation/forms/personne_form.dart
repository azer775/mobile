import 'package:flutter/material.dart';
import '../../core/utils/validators.dart';
import '../../data/models/entities/personne_entity.dart';
import '../../data/models/enums/parcelle_enums.dart';
import '../screens/qr_scanner_screen.dart';

/// Personne form for creating and editing personnes
/// 
/// This form is used within the ImmobilierWizard as Step 2.
/// It can also be used standalone for editing existing personnes.
class PersonneForm extends StatefulWidget {
  final PersonneEntity? personne;
  final int? parcelleId;
  final Function(PersonneEntity) onSave;
  final bool showAppBar;

  const PersonneForm({
    super.key,
    this.personne,
    this.parcelleId,
    required this.onSave,
    this.showAppBar = true,
  });

  @override
  State<PersonneForm> createState() => PersonneFormState();
}

class PersonneFormState extends State<PersonneForm> {
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  late final TextEditingController _nomRaisonSocialeController;
  late final TextEditingController _nifController;
  late final TextEditingController _contactController;
  late final TextEditingController _adressePostaleController;

  // Dropdown values
  TypePersonne _typePersonne = TypePersonne.physique;

  // UI state
  bool _isLoading = false;

  bool get _isEditing => widget.personne != null;
  bool get _isMorale => _typePersonne == TypePersonne.morale;

  /// Strip +243 prefix from phone number for display in text field
  String _stripPhonePrefix(String? phone) {
    if (phone == null || phone.isEmpty) return '';
    return phone.startsWith('+243') ? phone.substring(4).trim() : phone;
  }

  /// Add +243 prefix to phone number when saving
  String _addPhonePrefix(String contact) {
    final trimmed = contact.trim();
    if (trimmed.isEmpty) return '';
    // Don't add prefix if it's an email or already has prefix
    if (trimmed.contains('@') || trimmed.startsWith('+')) return trimmed;
    return '+243$trimmed';
  }

  @override
  void initState() {
    super.initState();
    final p = widget.personne;

    _nomRaisonSocialeController = TextEditingController(text: p?.nomRaisonSociale ?? '');
    _nifController = TextEditingController(text: p?.nif ?? '');
    _contactController = TextEditingController(text: _stripPhonePrefix(p?.contact));
    _adressePostaleController = TextEditingController(text: p?.adressePostale ?? '');

    _typePersonne = p?.typePersonne ?? TypePersonne.physique;
  }

  @override
  void dispose() {
    _nomRaisonSocialeController.dispose();
    _nifController.dispose();
    _contactController.dispose();
    _adressePostaleController.dispose();
    super.dispose();
  }

  /// Public method to validate the form (called from wizard)
  bool validate() {
    return _formKey.currentState?.validate() ?? false;
  }

  /// Public method to get the current personne data
  PersonneEntity getData() {
    return PersonneEntity(
      id: widget.personne?.id,
      typePersonne: _typePersonne,
      nomRaisonSociale: _nomRaisonSocialeController.text.trim().isEmpty 
          ? null : _nomRaisonSocialeController.text.trim(),
      nif: _nifController.text.trim().isEmpty 
          ? null : _nifController.text.trim(),
      contact: _contactController.text.trim().isEmpty 
          ? null : _addPhonePrefix(_contactController.text),
      adressePostale: _adressePostaleController.text.trim().isEmpty 
          ? null : _adressePostaleController.text.trim(),
      parcelleId: widget.parcelleId ?? widget.personne?.parcelleId,
      createdAt: widget.personne?.createdAt,
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
            // TYPE DE PERSONNE
            _buildSectionTitle('Type de Personne'),
            const SizedBox(height: 8),
            DropdownButtonFormField<TypePersonne>(
              value: _typePersonne,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.person_pin),
              ),
              items: TypePersonne.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.value.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _typePersonne = value);
                }
              },
            ),
            const SizedBox(height: 24),

            // IDENTITÉ
            _buildSectionTitle(_isMorale ? 'Raison Sociale' : 'Identité'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nomRaisonSocialeController,
              decoration: InputDecoration(
                labelText: _isMorale ? 'Raison Sociale *' : 'Nom Complet *',
                prefixIcon: Icon(_isMorale ? Icons.business : Icons.person),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) =>
                  Validators.required(value, fieldName: _isMorale ? 'Raison sociale' : 'Nom'),
            ),
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
                labelText: 'Téléphone / Email',
                prefixIcon: Icon(Icons.phone),
                prefixText: '+243 ',
                hintText: 'ou entrez un email',
              ),
              keyboardType: TextInputType.phone,
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
