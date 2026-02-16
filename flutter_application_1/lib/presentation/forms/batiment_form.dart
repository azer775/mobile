import 'package:flutter/material.dart';
import '../../data/models/entities/batiment_entity.dart';
import '../../data/models/enums/parcelle_enums.dart';

/// Batiment form for creating and editing batiments
/// 
/// This form is used within a dialog or bottom sheet to add/edit batiments.
class BatimentForm extends StatefulWidget {
  final BatimentEntity? batiment;
  final int? parcelleId;
  final Function(BatimentEntity) onSave;

  const BatimentForm({
    super.key,
    this.batiment,
    this.parcelleId,
    required this.onSave,
  });

  @override
  State<BatimentForm> createState() => _BatimentFormState();
}

class _BatimentFormState extends State<BatimentForm> {
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  late final TextEditingController _nombreEtagesController;
  late final TextEditingController _anneeConstructionController;
  late final TextEditingController _surfaceBatieController;

  // Dropdown values
  TypeBatiment _typeBatiment = TypeBatiment.maison;
  UsagePrincipal _usagePrincipal = UsagePrincipal.residentiel;
  StatutBatiment _statutBatiment = StatutBatiment.enService;

  bool get _isEditing => widget.batiment != null;

  @override
  void initState() {
    super.initState();
    final b = widget.batiment;

    _nombreEtagesController = TextEditingController(
      text: b?.nombreEtages?.toString() ?? '',
    );
    _anneeConstructionController = TextEditingController(
      text: b?.anneeConstruction?.toString() ?? '',
    );
    _surfaceBatieController = TextEditingController(
      text: b?.surfaceBatieM2?.toString() ?? '',
    );

    _typeBatiment = b?.typeBatiment ?? TypeBatiment.maison;
    _usagePrincipal = b?.usagePrincipal ?? UsagePrincipal.residentiel;
    _statutBatiment = b?.statutBatiment ?? StatutBatiment.enService;
  }

  @override
  void dispose() {
    _nombreEtagesController.dispose();
    _anneeConstructionController.dispose();
    _surfaceBatieController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;

    final batiment = BatimentEntity(
      id: widget.batiment?.id,
      parcelleId: widget.parcelleId ?? widget.batiment?.parcelleId,
      typeBatiment: _typeBatiment,
      nombreEtages: _nombreEtagesController.text.trim().isEmpty 
          ? null : int.tryParse(_nombreEtagesController.text.trim()),
      anneeConstruction: _anneeConstructionController.text.trim().isEmpty 
          ? null : int.tryParse(_anneeConstructionController.text.trim()),
      surfaceBatieM2: _surfaceBatieController.text.trim().isEmpty 
          ? null : double.tryParse(_surfaceBatieController.text.trim()),
      usagePrincipal: _usagePrincipal,
      statutBatiment: _statutBatiment,
      createdAt: widget.batiment?.createdAt,
      updatedAt: DateTime.now(),
    );

    widget.onSave(batiment);
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
              _isEditing ? 'Modifier Bâtiment' : 'Nouveau Bâtiment',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),

            // TYPE DE BATIMENT
            _buildSectionTitle('Type de Bâtiment'),
            const SizedBox(height: 8),
            DropdownButtonFormField<TypeBatiment>(
              value: _typeBatiment,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.home_work),
              ),
              items: TypeBatiment.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.value.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _typeBatiment = value);
                }
              },
            ),
            const SizedBox(height: 16),

            // CARACTÉRISTIQUES
            _buildSectionTitle('Caractéristiques'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _nombreEtagesController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre d\'étages',
                      prefixIcon: Icon(Icons.layers),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _anneeConstructionController,
                    decoration: const InputDecoration(
                      labelText: 'Année construction',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _surfaceBatieController,
              decoration: const InputDecoration(
                labelText: 'Surface bâtie (m²)',
                prefixIcon: Icon(Icons.square_foot),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),

            // USAGE PRINCIPAL
            _buildSectionTitle('Usage Principal'),
            const SizedBox(height: 8),
            DropdownButtonFormField<UsagePrincipal>(
              value: _usagePrincipal,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.category),
              ),
              items: UsagePrincipal.values.map((usage) {
                return DropdownMenuItem(
                  value: usage,
                  child: Text(usage.value.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _usagePrincipal = value);
                }
              },
            ),
            const SizedBox(height: 16),

            // STATUT
            _buildSectionTitle('Statut du Bâtiment'),
            const SizedBox(height: 8),
            DropdownButtonFormField<StatutBatiment>(
              value: _statutBatiment,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.info),
              ),
              items: StatutBatiment.values.map((statut) {
                return DropdownMenuItem(
                  value: statut,
                  child: Text(statut.value.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _statutBatiment = value);
                }
              },
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
