import 'package:flutter/material.dart';
import '../../data/models/entities/parcelle_entity.dart';
import '../../data/models/enums/parcelle_enums.dart';

/// List tile widget for displaying a parcelle in a list
class ParcelleListTile extends StatelessWidget {
  final ParcelleEntity parcelle;
  final int batimentCount;
  final String? proprietaire;
  final VoidCallback onTap;

  const ParcelleListTile({
    super.key,
    required this.parcelle,
    this.batimentCount = 0,
    this.proprietaire,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getStatusColor(parcelle.statutParcelle).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.landscape,
            color: _getStatusColor(parcelle.statutParcelle),
          ),
        ),
        title: Text(
          parcelle.codeParcelle ?? 'Parcelle ${parcelle.id}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${parcelle.quartier ?? ""}${parcelle.quartier != null && parcelle.commune != null ? ", " : ""}${parcelle.commune ?? ""}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(parcelle.statutParcelle),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    parcelle.statutParcelle.value,
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
                if (parcelle.hasGps) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.location_on, size: 14, color: Colors.green),
                ],
                if (batimentCount > 0) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.home_work, size: 14, color: Colors.grey.shade600),
                  Text(' $batimentCount',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                ],
              ],
            ),
          ],
        ),
        isThreeLine: true,
        trailing: proprietaire != null
            ? Container(
                constraints: const BoxConstraints(maxWidth: 80),
                child: Text(
                  proprietaire!,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              )
            : null,
        onTap: onTap,
      ),
    );
  }

  Color _getStatusColor(StatutParcelle status) {
    switch (status) {
      case StatutParcelle.active:
        return Colors.green;
      case StatutParcelle.fusionnee:
        return Colors.blue;
      case StatutParcelle.subdivisee:
        return Colors.orange;
      case StatutParcelle.archivee:
        return Colors.grey;
    }
  }
}
