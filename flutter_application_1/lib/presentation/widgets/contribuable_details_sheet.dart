import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/entities/contribuable_entity.dart';
import '../../data/models/enums/contribuable_enums.dart';

/// Bottom sheet widget for displaying contribuable details
class ContribuableDetailsSheet extends StatelessWidget {
  final ContribuableEntity contribuable;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ContribuableDetailsSheet({
    super.key,
    required this.contribuable,
    required this.onEdit,
    required this.onDelete,
  });

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
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: contribuable.mainPhoto != null
                        ? FileImage(File(contribuable.mainPhoto!))
                        : null,
                    child: contribuable.mainPhoto == null
                        ? Icon(
                            contribuable.typeContribuable == TypeContribuable.morale
                                ? Icons.business
                                : Icons.person,
                            size: 30,
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contribuable.fullName,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          contribuable.typeContribuable.displayName,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Details
              _buildDetailRow(Icons.badge, 'NIF', contribuable.nif ?? 'Non défini'),
              if (contribuable.typeNif != null)
                _buildDetailRow(Icons.category, 'Type NIF', contribuable.typeNif!.value),
              _buildDetailRow(Icons.phone, 'Téléphone 1', contribuable.telephone1),
              if (contribuable.telephone2 != null)
                _buildDetailRow(Icons.phone_android, 'Téléphone 2', contribuable.telephone2!),
              if (contribuable.email != null)
                _buildDetailRow(Icons.email, 'Email', contribuable.email!),
              _buildDetailRow(Icons.location_on, 'Adresse', contribuable.adresse),
              if (contribuable.hasLocation)
                _buildDetailRow(
                  Icons.my_location,
                  'GPS',
                  '${contribuable.gpsLatitude!.toStringAsFixed(6)}, ${contribuable.gpsLongitude!.toStringAsFixed(6)}',
                ),
              _buildDetailRow(Icons.source, 'Origine', contribuable.origineFiche.displayName),
              _buildDetailRow(Icons.person, 'Créé par', contribuable.creePar),

              const SizedBox(height: 24),

              // Photos
              if (contribuable.pieceIdentiteUrls.isNotEmpty) ...[
                Text('Photos (${contribuable.pieceIdentiteUrls.length})',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: contribuable.pieceIdentiteUrls.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(contribuable.pieceIdentiteUrls[index]),
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              Text(value, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}
