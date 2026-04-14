import 'package:flutter/material.dart';
import '../../data/models/entities/contribuable_entity.dart';
import '../../data/models/entities/unite_entity.dart';
import '../../data/models/enums/parcelle_enums.dart';
import '../screens/qr_scanner_screen.dart';

/// Unite form for creating and editing unites within a batiment
///
/// Shown as a bottom sheet from the BatimentForm.
class UniteForm extends StatefulWidget {
  final UniteEntity? unite;
  final Function(UniteEntity) onSave;

  const UniteForm({
    super.key,
    this.unite,
    required this.onSave,
  });

  @override
  State<UniteForm> createState() => _UniteFormState();
}

class _UniteFormState extends State<UniteForm> {
  final _formKey = GlobalKey<FormState>();

  // Unite fields
  late final TextEditingController _superficieController;
  late final TextEditingController _montantLoyerController;

  // Locataire fields
  late final TextEditingController _nomController;
  late final TextEditingController _prenomController;
  late final TextEditingController _pieceIdentiteController;
  late final TextEditingController _nifController;
  late final TextEditingController _contactController;
  late final TextEditingController _emailController;
  late final TextEditingController _adressePostaleController;
  late final TextEditingController _nomRaisonSocialeController;

  // Dropdown / date values
  TypeUnite? _typeUnite;
  TypeContribuable _typeContribuable = TypeContribuable.physique;
  DateTime? _dateDebutLoyer;

  bool get _isEditing => widget.unite != null;

  /// Strip +243 prefix from phone number for display
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
    final u = widget.unite;
    final loc = u?.locataire;

    _superficieController = TextEditingController(
      text: u?.superficie?.toString() ?? '',
    );
    _montantLoyerController = TextEditingController(
      text: u?.montantLoyer?.toString() ?? '',
    );

    // Locataire fields
    _nomController = TextEditingController(text: loc?.nom ?? '');
    _prenomController = TextEditingController(text: loc?.prenom ?? '');
    _pieceIdentiteController = TextEditingController(text: loc?.pieceIdentite ?? '');
    _nifController = TextEditingController(text: loc?.nif ?? '');
    _contactController = TextEditingController(text: _stripPhonePrefix(loc?.contact));
    _emailController = TextEditingController(text: loc?.email ?? '');
    _adressePostaleController = TextEditingController(text: loc?.adressePostale ?? '');
    _nomRaisonSocialeController = TextEditingController(text: loc?.nomRaisonSociale ?? '');

    _typeUnite = u?.typeUnite;
    _typeContribuable = loc?.typeContribuable ?? TypeContribuable.physique;
    _dateDebutLoyer = u?.dateDebutLoyer;
  }

  @override
  void dispose() {
    _superficieController.dispose();
    _montantLoyerController.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    _pieceIdentiteController.dispose();
    _nifController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _adressePostaleController.dispose();
    _nomRaisonSocialeController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateDebutLoyer ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() => _dateDebutLoyer = picked);
    }
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;

    // Build a locataire ContribuableEntity if any locataire field is filled
    final bool hasLocataire;
    if (_typeContribuable == TypeContribuable.morale) {
      hasLocataire = _nomRaisonSocialeController.text.trim().isNotEmpty ||
          _nifController.text.trim().isNotEmpty ||
          _contactController.text.trim().isNotEmpty;
    } else {
      hasLocataire = _nomController.text.trim().isNotEmpty ||
          _prenomController.text.trim().isNotEmpty ||
          _nifController.text.trim().isNotEmpty ||
          _contactController.text.trim().isNotEmpty;
    }

    ContribuableEntity? locataire;
    if (hasLocataire) {
      locataire = ContribuableEntity(
        id: widget.unite?.locataire?.id,
        typeContribuable: _typeContribuable,
        nom: _typeContribuable == TypeContribuable.physique && _nomController.text.trim().isNotEmpty
            ? _nomController.text.trim() : null,
        prenom: _typeContribuable == TypeContribuable.physique && _prenomController.text.trim().isNotEmpty
            ? _prenomController.text.trim() : null,
        pieceIdentite: _typeContribuable == TypeContribuable.physique && _pieceIdentiteController.text.trim().isNotEmpty
            ? _pieceIdentiteController.text.trim() : null,
        nomRaisonSociale: _typeContribuable == TypeContribuable.morale && _nomRaisonSocialeController.text.trim().isNotEmpty
            ? _nomRaisonSocialeController.text.trim() : null,
        nif: _nifController.text.trim().isEmpty
            ? null : _nifController.text.trim(),
        contact: _contactController.text.trim().isEmpty
            ? null : _addPhonePrefix(_contactController.text),
        email: _emailController.text.trim().isEmpty
            ? null : _emailController.text.trim(),
        adressePostale: _adressePostaleController.text.trim().isEmpty
            ? null : _adressePostaleController.text.trim(),
      );
    }

    final unite = UniteEntity(
      id: widget.unite?.id,
      batimentId: widget.unite?.batimentId,
      typeUnite: _typeUnite,
      superficie: _superficieController.text.trim().isEmpty
          ? null
          : double.tryParse(_superficieController.text.trim()),
      contribuableId: widget.unite?.contribuableId,
      locataire: locataire,
      montantLoyer: _montantLoyerController.text.trim().isEmpty
          ? null
          : double.tryParse(_montantLoyerController.text.trim()),
      dateDebutLoyer: _dateDebutLoyer,
      createdAt: widget.unite?.createdAt,
      updatedAt: DateTime.now(),
    );

    widget.onSave(unite);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Text(
              _isEditing ? 'Modifier Unité' : 'Nouvelle Unité',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),

            // UNITÉ SECTION
            _buildSectionTitle('Unité'),
            const SizedBox(height: 8),
            DropdownButtonFormField<TypeUnite>(
              value: _typeUnite,
              decoration: const InputDecoration(
                labelText: 'Type d\'unité',
                prefixIcon: Icon(Icons.door_front_door),
                hintText: 'Sélectionner un type',
              ),
              items: [
                const DropdownMenuItem<TypeUnite>(
                  value: null,
                  child: Text('-- Aucun --'),
                ),
                ...TypeUnite.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.value),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() => _typeUnite = value);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _superficieController,
              decoration: const InputDecoration(
                labelText: 'Superficie (m²)',
                prefixIcon: Icon(Icons.square_foot),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 24),

            // LOCATAIRE SECTION
            _buildSectionTitle('Locataire'),
            const SizedBox(height: 8),
            DropdownButtonFormField<TypeContribuable>(
              value: _typeContribuable,
              decoration: const InputDecoration(
                labelText: 'Type de contribuable',
                prefixIcon: Icon(Icons.category),
              ),
              items: TypeContribuable.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type == TypeContribuable.physique
                      ? 'Personne physique'
                      : 'Personne morale'),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _typeContribuable = value);
              },
            ),
            const SizedBox(height: 12),

            // Conditional fields based on type
            if (_typeContribuable == TypeContribuable.physique) ...[
              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom',
                  prefixIcon: Icon(Icons.person),
                ),
                textCapitalization: TextCapitalization.words,
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
            ] else ...[
              TextFormField(
                controller: _nomRaisonSocialeController,
                decoration: const InputDecoration(
                  labelText: 'Raison Sociale',
                  prefixIcon: Icon(Icons.business),
                ),
                textCapitalization: TextCapitalization.words,
              ),
            ],
            const SizedBox(height: 12),
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
            const SizedBox(height: 12),
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
            const SizedBox(height: 12),
            TextFormField(
              controller: _montantLoyerController,
              decoration: const InputDecoration(
                labelText: 'Montant du loyer',
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),

            // Date début loyer
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date début du loyer',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _dateDebutLoyer != null
                          ? '${_dateDebutLoyer!.day.toString().padLeft(2, '0')}/${_dateDebutLoyer!.month.toString().padLeft(2, '0')}/${_dateDebutLoyer!.year}'
                          : 'Sélectionner une date',
                      style: TextStyle(
                        color: _dateDebutLoyer != null
                            ? null
                            : Colors.grey.shade600,
                      ),
                    ),
                    if (_dateDebutLoyer != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          setState(() => _dateDebutLoyer = null);
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // BUTTONS
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _onSubmit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      _isEditing ? 'Modifier' : 'Ajouter',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
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
