import 'package:flutter/material.dart';
import '../../core/services/parcelle_export_service.dart';
import '../../core/utils/success_popup.dart';
import '../../data/datasources/local/parcelle_local_datasource.dart';
import '../../data/datasources/local/personne_local_datasource.dart';
import '../../data/datasources/local/batiment_local_datasource.dart';
import '../../data/models/entities/parcelle_entity.dart';
import '../../data/models/entities/personne_entity.dart';
import '../../data/models/entities/batiment_entity.dart';
import '../../data/models/enums/parcelle_enums.dart';
import '../forms/immobilier_wizard.dart';
import '../widgets/parcelle_list_tile.dart';
import '../widgets/parcelle_details_sheet.dart';

/// Immobilier (Parcelles) list page
class ImmobilierPage extends StatefulWidget {
  const ImmobilierPage({super.key});

  @override
  State<ImmobilierPage> createState() => _ImmobilierPageState();
}

class _ImmobilierPageState extends State<ImmobilierPage> {
  final ParcelleLocalDatasource _parcelleDatasource = ParcelleLocalDatasource();
  final PersonneLocalDatasource _personneDatasource = PersonneLocalDatasource();
  final BatimentLocalDatasource _batimentDatasource = BatimentLocalDatasource();
  final TextEditingController _searchController = TextEditingController();

  List<ParcelleEntity> _parcelles = [];
  List<ParcelleEntity> _filteredParcelles = [];
  Map<int, PersonneEntity?> _personneByParcelleId = {};
  Map<int, int> _batimentCountByParcelleId = {};
  bool _isLoading = false;
  StatutParcelle? _filterStatus;

  @override
  void initState() {
    super.initState();
    _loadParcelles();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterParcelles();
  }

  void _filterParcelles() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredParcelles = _parcelles.where((p) {
        // Filter by status if selected
        if (_filterStatus != null && p.statutParcelle != _filterStatus) {
          return false;
        }
        // Filter by search query
        if (query.isEmpty) return true;
        return (p.codeParcelle?.toLowerCase().contains(query) ?? false) ||
            (p.commune?.toLowerCase().contains(query) ?? false) ||
            (p.quartier?.toLowerCase().contains(query) ?? false) ||
            (p.referenceCadastrale?.toLowerCase().contains(query) ?? false);
      }).toList();
    });
  }

  Future<void> _loadParcelles() async {
    setState(() => _isLoading = true);
    try {
      final parcelles = await _parcelleDatasource.getAllParcelles();
      
      // Load associated data for each parcelle
      final personneMap = <int, PersonneEntity?>{};
      final batimentCountMap = <int, int>{};
      
      for (final parcelle in parcelles) {
        if (parcelle.id != null) {
          personneMap[parcelle.id!] = await _personneDatasource.getPersonneByParcelleId(parcelle.id!);
          batimentCountMap[parcelle.id!] = await _batimentDatasource.countBatimentsByParcelleId(parcelle.id!);
        }
      }

      setState(() {
        _parcelles = parcelles;
        _personneByParcelleId = personneMap;
        _batimentCountByParcelleId = batimentCountMap;
        _filterParcelles();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de chargement: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteParcelle(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text(
          'Voulez-vous vraiment supprimer cette parcelle?\n\n'
          'Cela supprimera également le propriétaire et tous les bâtiments associés.',
        ),
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

    if (confirm != true) return;

    try {
      await _parcelleDatasource.deleteParcelle(id);
      await _loadParcelles();
      if (mounted) {
        await SuccessPopup.showDeleteSuccess(context, itemName: 'La parcelle');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _exportParcelles() async {
    if (!mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            SizedBox(width: 16),
            Expanded(child: Text('Export en cours...')),
          ],
        ),
      ),
    );

    try {
      final result = await ParcelleExportService.instance.exportAll(
        chunkSize: 20,
      );

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      await _loadParcelles();

      if (!mounted) return;
      final isSuccess = result.failedCount == 0;
      final message = isSuccess
          ? '${result.syncedCount} parcelle(s) exportée(s) avec succès'
          : 'Export partiel: ${result.syncedCount} succès, ${result.failedCount} échec(s)';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isSuccess ? Colors.green : Colors.orange,
        ),
      );
    } catch (error) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur export: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToAdd() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImmobilierWizard(
          onComplete: _loadParcelles,
        ),
      ),
    );
  }

  void _navigateToEdit(int parcelleId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImmobilierWizard(
          parcelleId: parcelleId,
          onComplete: _loadParcelles,
        ),
      ),
    );
  }

  void _showDetails(ParcelleEntity parcelle) async {
    PersonneEntity? personne;
    List<BatimentEntity> batiments = [];

    if (parcelle.id != null) {
      personne = await _personneDatasource.getPersonneByParcelleId(parcelle.id!);
      batiments = await _batimentDatasource.getBatimentsByParcelleId(parcelle.id!);
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ParcelleDetailsSheet(
        parcelle: parcelle,
        personne: personne,
        batiments: batiments,
        onEdit: () {
          Navigator.pop(context);
          _navigateToEdit(parcelle.id!);
        },
        onDelete: () {
          Navigator.pop(context);
          _deleteParcelle(parcelle.id!);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Immobilier'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Exporter',
            onPressed: _exportParcelles,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadParcelles,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAdd,
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle Parcelle'),
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('Tous'),
                        selected: _filterStatus == null,
                        onSelected: (_) {
                          setState(() => _filterStatus = null);
                          _filterParcelles();
                        },
                      ),
                      const SizedBox(width: 8),
                      ...StatutParcelle.values.map((status) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(status.value),
                            selected: _filterStatus == status,
                            onSelected: (_) {
                              setState(() => _filterStatus = status);
                              _filterParcelles();
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${_filteredParcelles.length} parcelle(s)',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredParcelles.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.landscape_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isNotEmpty
                                  ? 'Aucun résultat trouvé'
                                  : 'Aucune parcelle',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadParcelles,
                        child: ListView.builder(
                          itemCount: _filteredParcelles.length,
                          itemBuilder: (context, index) {
                            final p = _filteredParcelles[index];
                            final personne = _personneByParcelleId[p.id];
                            final batimentCount = _batimentCountByParcelleId[p.id] ?? 0;
                            return ParcelleListTile(
                              parcelle: p,
                              batimentCount: batimentCount,
                              proprietaire: personne?.displayName,
                              onTap: () => _showDetails(p),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
