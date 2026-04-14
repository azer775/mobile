import 'package:flutter/material.dart';
import '../../data/models/entities/batiment_entity.dart';
import '../../data/models/entities/unite_entity.dart';
import '../../data/models/enums/parcelle_enums.dart';
import 'unite_form.dart';

/// Batiment form for creating and editing batiments
///
/// This form is used within a dialog or bottom sheet to add/edit batiments.
/// It includes an inline list of unités that can be added/edited/deleted.
class BatimentForm extends StatefulWidget {
  final BatimentEntity? batiment;
  final int? parcelleId;
  final List<UniteEntity> unites;
  final Function(BatimentEntity, List<UniteEntity>) onSave;

  const BatimentForm({
    super.key,
    this.batiment,
    this.parcelleId,
    this.unites = const [],
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

  // Unités list
  late List<UniteEntity> _unites;

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

    _unites = List.from(widget.unites);
  }

  @override
  void dispose() {
    _nombreEtagesController.dispose();
    _anneeConstructionController.dispose();
    _surfaceBatieController.dispose();
    super.dispose();
  }

  void _addUnite() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: UniteForm(
          onSave: (unite) {
            setState(() {
              _unites.add(unite);
            });
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _editUnite(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: UniteForm(
          unite: _unites[index],
          onSave: (unite) {
            setState(() {
              _unites[index] = unite;
            });
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _deleteUnite(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer cette unité?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _unites.removeAt(index);
      });
    }
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;

    final batiment = BatimentEntity(
      id: widget.batiment?.id,
      parcelleId: widget.parcelleId ?? widget.batiment?.parcelleId,
      typeBatiment: _typeBatiment,
      nombreEtages: _nombreEtagesController.text.trim().isEmpty
          ? null
          : int.tryParse(_nombreEtagesController.text.trim()),
      anneeConstruction: _anneeConstructionController.text.trim().isEmpty
          ? null
          : int.tryParse(_anneeConstructionController.text.trim()),
      surfaceBatieM2: _surfaceBatieController.text.trim().isEmpty
          ? null
          : double.tryParse(_surfaceBatieController.text.trim()),
      usagePrincipal: _usagePrincipal,
      statutBatiment: _statutBatiment,
      createdAt: widget.batiment?.createdAt,
      updatedAt: DateTime.now(),
    );

    widget.onSave(batiment, _unites);
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
                  setState(() {
                    _typeBatiment = value;
                    // Clear unités when switching away from immeuble
                    if (value != TypeBatiment.immeuble) {
                      _unites.clear();
                    }
                  });
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
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
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
            const SizedBox(height: 24),

            // UNITÉS SECTION (only for Immeuble)
            if (_typeBatiment == TypeBatiment.immeuble) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle('Unités (${_unites.length})'),
                  TextButton.icon(
                    onPressed: _addUnite,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Ajouter'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_unites.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Center(
                    child: Text(
                      'Aucune unité ajoutée',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ),
                ),
              ...List.generate(_unites.length, (index) {
                final unite = _unites[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.door_front_door,
                      color: Theme.of(context).primaryColor,
                    ),
                    title: Text(
                      unite.typeUnite?.value ?? 'Unité ${index + 1}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      [
                        if (unite.superficie != null) '${unite.superficie} m²',
                        if (unite.locataire != null) unite.locataire!.displayName,
                      ].join(' • '),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: () => _editUnite(index),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 18,
                              color: Colors.red),
                          onPressed: () => _deleteUnite(index),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    onTap: () => _editUnite(index),
                  ),
                );
              }),
            ],
            const SizedBox(height: 24),

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
