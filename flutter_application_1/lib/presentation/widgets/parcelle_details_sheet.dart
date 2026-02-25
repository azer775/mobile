import 'package:flutter/material.dart';
import '../../data/datasources/local/ref_commune_local_datasource.dart';
import '../../data/datasources/local/ref_quartier_local_datasource.dart';
import '../../data/datasources/local/ref_avenue_local_datasource.dart';
import '../../data/models/entities/parcelle_entity.dart';
import '../../data/models/entities/personne_entity.dart';
import '../../data/models/entities/batiment_entity.dart';
import '../../data/models/enums/parcelle_enums.dart';

/// Bottom sheet widget for displaying parcelle details
class ParcelleDetailsSheet extends StatefulWidget {
  final ParcelleEntity parcelle;
  final PersonneEntity? personne;
  final List<BatimentEntity> batiments;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ParcelleDetailsSheet({
    super.key,
    required this.parcelle,
    this.personne,
    this.batiments = const [],
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<ParcelleDetailsSheet> createState() => _ParcelleDetailsSheetState();
}

class _ParcelleDetailsSheetState extends State<ParcelleDetailsSheet> {
  String? _communeLabel;
  String? _quartierLabel;
  String? _avenueLabel;

  @override
  void initState() {
    super.initState();
    _loadRefLabels();
  }

  Future<void> _loadRefLabels() async {
    final parcelle = widget.parcelle;
    if (parcelle.communeId != null) {
      final communes = await RefCommuneLocalDatasource().getAllCommunes();
      final match = communes.where((c) => c.id == parcelle.communeId).firstOrNull;
      if (mounted && match != null) setState(() => _communeLabel = match.libelle);
    }
    if (parcelle.quartierId != null) {
      final quartiers = await RefQuartierLocalDatasource().getAllQuartiers();
      final match = quartiers.where((q) => q.id == parcelle.quartierId).firstOrNull;
      if (mounted && match != null) setState(() => _quartierLabel = match.libelle);
    }
    if (parcelle.avenueId != null) {
      final avenues = await RefAvenueLocalDatasource().getAllAvenues();
      final match = avenues.where((a) => a.id == parcelle.avenueId).firstOrNull;
      if (mounted && match != null) setState(() => _avenueLabel = match.libelle);
    }
  }

  ParcelleEntity get parcelle => widget.parcelle;
  PersonneEntity? get personne => widget.personne;
  List<BatimentEntity> get batiments => widget.batiments;
  VoidCallback get onEdit => widget.onEdit;
  VoidCallback get onDelete => widget.onDelete;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.landscape,
                      size: 30,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          parcelle.codeParcelle ?? 'Parcelle ${parcelle.id}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          parcelle.statutParcelle.value,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Parcelle Details
              _buildSectionTitle(context, 'Informations Parcelle'),
              const SizedBox(height: 8),
              if (parcelle.referenceCadastrale != null)
                _buildDetailRow(Icons.article, 'Réf. Cadastrale', parcelle.referenceCadastrale!),
              _buildDetailRow(Icons.location_city, 'Commune', _communeLabel ?? parcelle.commune ?? 'Non définie'),
              _buildDetailRow(Icons.holiday_village, 'Quartier', _quartierLabel ?? parcelle.quartier ?? 'Non défini'),
              if (_avenueLabel != null || parcelle.rueAvenue != null)
                _buildDetailRow(Icons.signpost, 'Avenue', _avenueLabel ?? parcelle.rueAvenue ?? ''),
              if (parcelle.rue != null)
                _buildDetailRow(Icons.edit_road, 'Rue', parcelle.rue!),
              if (parcelle.numeroParcelle != null || parcelle.numeroAdresse != null)
                _buildDetailRow(
                  Icons.home,
                  'N° Parcelle',
                  parcelle.numeroParcelle ?? parcelle.numeroAdresse ?? '',
                ),
              if (parcelle.superficieM2 != null)
                _buildDetailRow(Icons.square_foot, 'Superficie', '${parcelle.superficieM2} m²'),
              if (parcelle.hasGps)
                _buildDetailRow(
                  Icons.my_location,
                  'GPS',
                  '${parcelle.gpsLat!.toStringAsFixed(6)}, ${parcelle.gpsLon!.toStringAsFixed(6)}',
                ),

              const SizedBox(height: 16),

              // Proprietaire
              if (personne != null) ...[
                _buildSectionTitle(context, 'Propriétaire'),
                const SizedBox(height: 8),
                _buildDetailRow(
                  personne!.typePersonne.value == 'physique' ? Icons.person : Icons.business,
                  personne!.typePersonne.value.toUpperCase(),
                  personne!.displayName,
                ),
                if (personne!.nif != null)
                  _buildDetailRow(Icons.badge, 'NIF', personne!.nif!),
                if (personne!.contact != null)
                  _buildDetailRow(Icons.phone, 'Contact', personne!.contact!),
                if (personne!.adressePostale != null)
                  _buildDetailRow(Icons.mail, 'Adresse Postale', personne!.adressePostale!),
                const SizedBox(height: 16),
              ],

              // Batiments
              if (batiments.isNotEmpty) ...[
                _buildSectionTitle(context, 'Bâtiments (${batiments.length})'),
                const SizedBox(height: 8),
                ...batiments.map((batiment) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getBatimentIcon(batiment.typeBatiment),
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  batiment.typeBatiment.value.toUpperCase(),
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  '${batiment.usagePrincipal.value} • ${batiment.nombreEtages ?? "?"} étage(s)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(batiment.statutBatiment),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              batiment.statutBatiment.value,
                              style: const TextStyle(color: Colors.white, fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 16),
              ],

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit),
                      label: const Text('Modifier'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                Text(value),
              ],
            ),
          ),
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

  Color _getStatusColor(StatutBatiment status) {
    switch (status) {
      case StatutBatiment.enService:
        return Colors.green;
      case StatutBatiment.enRuine:
        return Colors.red;
      case StatutBatiment.enChantier:
        return Colors.orange;
      case StatutBatiment.autre:
        return Colors.grey;
    }
  }
}
