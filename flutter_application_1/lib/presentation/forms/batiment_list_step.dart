import 'package:flutter/material.dart';
import '../../data/models/entities/batiment_entity.dart';
import '../../data/models/enums/parcelle_enums.dart';
import 'batiment_form.dart';

/// Batiment list step widget for the ImmobilierWizard (Step 3)
/// 
/// Allows users to add, view, and delete multiple batiments.
class BatimentListStep extends StatefulWidget {
  final List<BatimentEntity> batiments;
  final Function(List<BatimentEntity>) onBatimentsChanged;

  const BatimentListStep({
    super.key,
    required this.batiments,
    required this.onBatimentsChanged,
  });

  @override
  State<BatimentListStep> createState() => BatimentListStepState();
}

class BatimentListStepState extends State<BatimentListStep> {
  late List<BatimentEntity> _batiments;

  @override
  void initState() {
    super.initState();
    _batiments = List.from(widget.batiments);
  }

  /// Public method to get current batiments list
  List<BatimentEntity> getData() {
    return _batiments;
  }

  void _addBatiment() {
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
        child: BatimentForm(
          onSave: (batiment) {
            setState(() {
              _batiments.add(batiment);
            });
            widget.onBatimentsChanged(_batiments);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _editBatiment(int index) {
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
        child: BatimentForm(
          batiment: _batiments[index],
          onSave: (batiment) {
            setState(() {
              _batiments[index] = batiment;
            });
            widget.onBatimentsChanged(_batiments);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _deleteBatiment(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer ce bâtiment?'),
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
        _batiments.removeAt(index);
      });
      widget.onBatimentsChanged(_batiments);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bâtiments (${_batiments.length})',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              ElevatedButton.icon(
                onPressed: _addBatiment,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Empty state
          if (_batiments.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  Icon(Icons.home_work_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun bâtiment ajouté',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Appuyez sur "Ajouter" pour ajouter un bâtiment',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),

          // Batiments list
          ...List.generate(_batiments.length, (index) {
            final batiment = _batiments[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getBatimentIcon(batiment.typeBatiment),
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                title: Text(
                  batiment.typeBatiment.value.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${batiment.usagePrincipal.value} • ${batiment.nombreEtages ?? "?"} étage(s)',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () => _editBatiment(index),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                      onPressed: () => _deleteBatiment(index),
                    ),
                  ],
                ),
                onTap: () => _editBatiment(index),
              ),
            );
          }),
        ],
      ),
    );
  }

  IconData _getBatimentIcon(TypeBatiment type) {
    switch (type) {
      case TypeBatiment.maison:
        return Icons.home;
      case TypeBatiment.immeuble:
        return Icons.apartment;
      case TypeBatiment.entrepot:
        return Icons.warehouse;
      case TypeBatiment.commerce:
        return Icons.store;
      case TypeBatiment.bureau:
        return Icons.business;
      case TypeBatiment.autre:
        return Icons.home_work;
    }
  }
}
