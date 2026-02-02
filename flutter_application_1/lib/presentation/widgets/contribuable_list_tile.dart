import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/entities/contribuable_entity.dart';
import '../../data/models/enums/contribuable_enums.dart';

/// List tile widget for displaying a contribuable in a list
class ContribuableListTile extends StatelessWidget {
  final ContribuableEntity contribuable;
  final VoidCallback onTap;

  const ContribuableListTile({
    super.key,
    required this.contribuable,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: contribuable.mainPhoto != null
              ? FileImage(File(contribuable.mainPhoto!))
              : null,
          child: contribuable.mainPhoto == null
              ? Icon(
                  contribuable.typeContribuable == TypeContribuable.morale
                      ? Icons.business
                      : Icons.person,
                )
              : null,
        ),
        title: Text(
          contribuable.fullName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(contribuable.telephone1),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getTypeColor(contribuable.typeContribuable),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    contribuable.typeContribuable.displayName,
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
                if (contribuable.hasLocation) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.location_on, size: 14, color: Colors.green),
                ],
                if (contribuable.pieceIdentiteUrls.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.photo, size: 14, color: Colors.grey.shade600),
                  Text(' ${contribuable.pieceIdentiteUrls.length}',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                ],
              ],
            ),
          ],
        ),
        isThreeLine: true,
        trailing: contribuable.nif != null
            ? Chip(
                label: Text(contribuable.nif!, style: const TextStyle(fontSize: 10)),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              )
            : null,
        onTap: onTap,
      ),
    );
  }

  Color _getTypeColor(TypeContribuable type) {
    switch (type) {
      case TypeContribuable.physique:
        return Colors.blue;
      case TypeContribuable.morale:
        return Colors.purple;
      case TypeContribuable.informel:
        return Colors.orange;
    }
  }
}
