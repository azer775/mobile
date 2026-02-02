import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/success_popup.dart';
import '../../data/datasources/local/contribuable_local_datasource.dart';
import '../../data/models/entities/contribuable_entity.dart';
import '../../data/models/enums/contribuable_enums.dart';
import '../forms/contribuable_form.dart';
import '../widgets/contribuable_list_tile.dart';
import '../widgets/contribuable_details_sheet.dart';

/// Contribuables list page
class ContribuablesPage extends StatefulWidget {
  const ContribuablesPage({super.key});

  @override
  State<ContribuablesPage> createState() => _ContribuablesPageState();
}

class _ContribuablesPageState extends State<ContribuablesPage> {
  final ContribuableLocalDatasource _datasource = ContribuableLocalDatasource();
  final TextEditingController _searchController = TextEditingController();
  
  List<ContribuableEntity> _contribuables = [];
  List<ContribuableEntity> _filteredContribuables = [];
  bool _isLoading = false;
  TypeContribuable? _filterType;

  // Get current user from auth service
  String get _currentUser => AuthService.instance.currentUser ?? 'SYSTEM';

  @override
  void initState() {
    super.initState();
    _loadContribuables();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterContribuables();
  }

  void _filterContribuables() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredContribuables = _contribuables.where((c) {
        // Filter by type if selected
        if (_filterType != null && c.typeContribuable != _filterType) {
          return false;
        }
        // Filter by search query
        if (query.isEmpty) return true;
        return c.fullName.toLowerCase().contains(query) ||
            (c.nif?.toLowerCase().contains(query) ?? false) ||
            c.telephone1.contains(query) ||
            c.adresse.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _loadContribuables() async {
    setState(() => _isLoading = true);
    try {
      final contribuables = await _datasource.getAllContribuables();
      setState(() {
        _contribuables = contribuables;
        _filterContribuables();
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

  Future<void> _saveContribuable(ContribuableEntity contribuable) async {
    try {
      await _datasource.insertContribuable(contribuable);
      if (mounted) {
        await SuccessPopup.showAddSuccess(context, itemName: 'Le contribuable');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _updateContribuable(ContribuableEntity contribuable) async {
    try {
      await _datasource.updateContribuable(contribuable);
      if (mounted) {
        await SuccessPopup.showUpdateSuccess(context, itemName: 'Le contribuable');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _deleteContribuable(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer ce contribuable?'),
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
      await _datasource.deleteContribuable(id);
      await _loadContribuables();
      if (mounted) {
        await SuccessPopup.showDeleteSuccess(context, itemName: 'Le contribuable');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _navigateToAdd() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContribuableForm(
          currentUser: _currentUser,
          onSave: (contribuable) async {
            await _saveContribuable(contribuable);
            if (mounted) {
              Navigator.pop(context);
              _loadContribuables();
            }
          },
        ),
      ),
    );
  }

  void _navigateToEdit(ContribuableEntity contribuable) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContribuableForm(
          contribuable: contribuable,
          currentUser: _currentUser,
          onSave: (updated) async {
            await _updateContribuable(updated);
            if (mounted) {
              Navigator.pop(context);
              _loadContribuables();
            }
          },
        ),
      ),
    );
  }

  void _exportContribuables() {
    print('\n========== EXPORT CONTRIBUABLES ==========');
    print('Total: ${_filteredContribuables.length} contribuable(s)');
    print('Date: ${DateTime.now()}');
    print('==========================================\n');
    
    for (int i = 0; i < _filteredContribuables.length; i++) {
      final c = _filteredContribuables[i];
      print('--- Contribuable ${i + 1} ---');
      print('ID: ${c.id}');
      print('NIF: ${c.nif ?? "N/A"}');
      print('Type: ${c.typeContribuable.displayName}');
      print('Nom: ${c.fullName}');
      print('Téléphone: ${c.telephone1}');
      if (c.telephone2 != null && c.telephone2!.isNotEmpty) {
        print('Téléphone 2: ${c.telephone2}');
      }
      print('Email: ${c.email ?? "N/A"}');
      print('Adresse: ${c.adresse}');
      print('Origine: ${c.origineFiche.displayName}');
      if (c.hasLocation) {
        print('GPS: ${c.gpsLatitude}, ${c.gpsLongitude}');
      }
      print('Photos: ${c.pieceIdentiteUrls.length}');
      print('Créé par: ${c.creePar}');
      print('Date création: ${c.createdAt}');
      print('');
    }
    
    print('========== FIN EXPORT ==========\n');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_filteredContribuables.length} contribuable(s) exporté(s) dans la console'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contribuables'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Exporter',
            onPressed: _exportContribuables,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadContribuables,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAdd,
        icon: const Icon(Icons.add),
        label: const Text('Nouveau'),
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
                        selected: _filterType == null,
                        onSelected: (_) {
                          setState(() => _filterType = null);
                          _filterContribuables();
                        },
                      ),
                      const SizedBox(width: 8),
                      ...TypeContribuable.values.map((type) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(type.displayName),
                            selected: _filterType == type,
                            onSelected: (_) {
                              setState(() => _filterType = type);
                              _filterContribuables();
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
                  '${_filteredContribuables.length} contribuable(s)',
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
                : _filteredContribuables.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isNotEmpty
                                  ? 'Aucun résultat trouvé'
                                  : 'Aucun contribuable',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadContribuables,
                        child: ListView.builder(
                          itemCount: _filteredContribuables.length,
                          itemBuilder: (context, index) {
                            final c = _filteredContribuables[index];
                            return ContribuableListTile(
                              contribuable: c,
                              onTap: () => _showDetails(c),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  void _showDetails(ContribuableEntity contribuable) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ContribuableDetailsSheet(
        contribuable: contribuable,
        onEdit: () {
          Navigator.pop(context);
          _navigateToEdit(contribuable);
        },
        onDelete: () {
          Navigator.pop(context);
          _deleteContribuable(contribuable.id!);
        },
      ),
    );
  }
}
