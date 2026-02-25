# Guide : Consommer l'endpoint Batch Contribuables depuis Flutter

## Endpoint

```
POST /contribuables/batch
Content-Type: multipart/form-data
```

## Paramètres de la requête

| Nom du champ | Type | Obligatoire | Description |
|---|---|---|---|
| `data` | `String` (JSON) | ✅ Oui | Un tableau JSON de `ContribuableDto` |
| `creePar` | `String` | ✅ Oui | Le nom de l'utilisateur qui crée les enregistrements |
| `files_0` | `File(s)` | ❌ Non | Fichier(s) associé(s) au contribuable à l'index **0** du tableau JSON |
| `files_1` | `File(s)` | ❌ Non | Fichier(s) associé(s) au contribuable à l'index **1** du tableau JSON |
| `files_N` | `File(s)` | ❌ Non | Fichier(s) associé(s) au contribuable à l'index **N** du tableau JSON |

> **Convention** : `files_X` correspond au contribuable à l'index `X` dans le tableau JSON `data`.
> Chaque `files_X` peut contenir **plusieurs fichiers**.

---

## Structure du ContribuableDto (JSON)

```json
{
  "nif": "string",
  "typeNif": "string",
  "typeContribuable": "string",       // obligatoire (NOT NULL en DB)
  "nom": "string",
  "postNom": "string",
  "prenom": "string",
  "raisonSociale": "string",
  "telephone1": "string",             // obligatoire (NOT NULL en DB)
  "telephone2": "string",
  "email": "string",
  "rue": "string",
  "numeroParcelle": "string",
  "origineFiche": "string",           // obligatoire (NOT NULL en DB)
  "statut": 0,
  "gpsLatitude": 0.0,
  "gpsLongitude": 0.0,
  "pieceIdentiteUrl": "string",
  "dateInscription": "2026-02-24T00:00:00.000Z",
  "dateMaj": "2026-02-24T00:00:00.000Z",
  "formeJuridique": "string",
  "numeroRccm": "string",
  "refTypeActivite": 1,
  "refZoneType": 1,
  "refAvenue": 1,
  "refQuartier": 1,
  "refCommune": 1
}
```

---

## Dépendance Flutter requise

Ajouter `http` dans `pubspec.yaml` :

```yaml
dependencies:
  http: ^1.2.1
```

Puis exécuter :

```bash
flutter pub get
```

---

## Implémentation Flutter

### 1. Modèle Dart

```dart
class ContribuableDto {
  final String? nif;
  final String? typeNif;
  final String typeContribuable;
  final String? nom;
  final String? postNom;
  final String? prenom;
  final String? raisonSociale;
  final String telephone1;
  final String? telephone2;
  final String? email;
  final String? rue;
  final String? numeroParcelle;
  final String origineFiche;
  final int? statut;
  final double? gpsLatitude;
  final double? gpsLongitude;
  final String? pieceIdentiteUrl;
  final String? dateInscription;  // ISO 8601 format
  final String? dateMaj;          // ISO 8601 format
  final String? formeJuridique;
  final String? numeroRccm;
  final int? refTypeActivite;
  final int? refZoneType;
  final int? refAvenue;
  final int? refQuartier;
  final int? refCommune;

  ContribuableDto({
    this.nif,
    this.typeNif,
    required this.typeContribuable,
    this.nom,
    this.postNom,
    this.prenom,
    this.raisonSociale,
    required this.telephone1,
    this.telephone2,
    this.email,
    this.rue,
    this.numeroParcelle,
    required this.origineFiche,
    this.statut,
    this.gpsLatitude,
    this.gpsLongitude,
    this.pieceIdentiteUrl,
    this.dateInscription,
    this.dateMaj,
    this.formeJuridique,
    this.numeroRccm,
    this.refTypeActivite,
    this.refZoneType,
    this.refAvenue,
    this.refQuartier,
    this.refCommune,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (nif != null) map['nif'] = nif;
    if (typeNif != null) map['typeNif'] = typeNif;
    map['typeContribuable'] = typeContribuable;
    if (nom != null) map['nom'] = nom;
    if (postNom != null) map['postNom'] = postNom;
    if (prenom != null) map['prenom'] = prenom;
    if (raisonSociale != null) map['raisonSociale'] = raisonSociale;
    map['telephone1'] = telephone1;
    if (telephone2 != null) map['telephone2'] = telephone2;
    if (email != null) map['email'] = email;
    if (rue != null) map['rue'] = rue;
    if (numeroParcelle != null) map['numeroParcelle'] = numeroParcelle;
    map['origineFiche'] = origineFiche;
    if (statut != null) map['statut'] = statut;
    if (gpsLatitude != null) map['gpsLatitude'] = gpsLatitude;
    if (gpsLongitude != null) map['gpsLongitude'] = gpsLongitude;
    if (pieceIdentiteUrl != null) map['pieceIdentiteUrl'] = pieceIdentiteUrl;
    if (dateInscription != null) map['dateInscription'] = dateInscription;
    if (dateMaj != null) map['dateMaj'] = dateMaj;
    if (formeJuridique != null) map['formeJuridique'] = formeJuridique;
    if (numeroRccm != null) map['numeroRccm'] = numeroRccm;
    if (refTypeActivite != null) map['refTypeActivite'] = refTypeActivite;
    if (refZoneType != null) map['refZoneType'] = refZoneType;
    if (refAvenue != null) map['refAvenue'] = refAvenue;
    if (refQuartier != null) map['refQuartier'] = refQuartier;
    if (refCommune != null) map['refCommune'] = refCommune;
    return map;
  }
}
```

### 2. Service d'envoi

```dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ContribuableService {
  static const String _baseUrl = 'http://10.0.2.2:8020'; // Android emulator
  // Pour un appareil physique, utiliser l'IP locale : 'http://192.168.x.x:8020'
  // Pour iOS simulator : 'http://localhost:8020'

  /// Envoie une liste de contribuables avec leurs fichiers respectifs.
  ///
  /// [contribuables] — la liste des ContribuableDto à enregistrer.
  /// [creePar] — le nom de l'utilisateur.
  /// [filesByIndex] — une Map où la clé est l'index du contribuable
  ///                   et la valeur est la liste des fichiers (File) associés.
  ///
  /// Exemple :
  ///   filesByIndex = {
  ///     0: [File('/path/to/doc1.pdf'), File('/path/to/doc2.jpg')],
  ///     2: [File('/path/to/doc3.png')],
  ///   }
  ///   → Le contribuable à l'index 0 aura 2 fichiers, l'index 1 aucun, l'index 2 un fichier.
  Future<String> saveContribuablesBatch({
    required List<ContribuableDto> contribuables,
    required String creePar,
    Map<int, List<File>>? filesByIndex,
  }) async {
    final uri = Uri.parse('$_baseUrl/contribuables/batch?creePar=$creePar');

    final request = http.MultipartRequest('POST', uri);

    // 1. Ajouter le JSON des contribuables dans le champ "data"
    final jsonString = jsonEncode(
      contribuables.map((c) => c.toJson()).toList(),
    );
    request.fields['data'] = jsonString;

    // 2. Ajouter les fichiers pour chaque contribuable
    if (filesByIndex != null) {
      for (final entry in filesByIndex.entries) {
        final index = entry.key;
        final files = entry.value;
        for (final file in files) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'files_$index', // files_0, files_1, files_2, ...
              file.path,
            ),
          );
        }
      }
    }

    // 3. Envoyer la requête
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return response.body; // "Opération terminée avec succès. X contribuable(s) enregistré(s)."
    } else {
      throw Exception('Erreur ${response.statusCode}: ${response.body}');
    }
  }
}
```

### 3. Exemple d'utilisation complet

```dart
import 'dart:io';

// Exemple dans un bouton ou un callback
Future<void> envoyerContribuables() async {
  final service = ContribuableService();

  // Préparer les contribuables
  final contribuables = [
    ContribuableDto(
      typeContribuable: 'PP',
      nom: 'Doe',
      prenom: 'John',
      telephone1: '0812345678',
      origineFiche: 'mobile',
      refTypeActivite: 1,
      refZoneType: 1,
      refAvenue: 1,
      refQuartier: 1,
      refCommune: 1,
    ),
    ContribuableDto(
      typeContribuable: 'PM',
      raisonSociale: 'ACME SARL',
      telephone1: '0898765432',
      origineFiche: 'mobile',
      email: 'contact@acme.cd',
      refTypeActivite: 2,
      refZoneType: 1,
      refAvenue: 1,
      refQuartier: 1,
      refCommune: 1,
    ),
  ];

  // Préparer les fichiers (optionnel)
  // Les fichiers peuvent venir de image_picker, file_picker, etc.
  final filesByIndex = {
    0: [
      File('/path/to/piece_identite_john.pdf'),
      File('/path/to/attestation_john.jpg'),
    ],
    1: [
      File('/path/to/rccm_acme.pdf'),
    ],
  };

  try {
    final result = await service.saveContribuablesBatch(
      contribuables: contribuables,
      creePar: 'admin',
      filesByIndex: filesByIndex,
    );
    print(result); // "Opération terminée avec succès. 2 contribuable(s) enregistré(s)."
  } catch (e) {
    print('Erreur: $e');
  }
}
```

---

## Schéma visuel de la requête HTTP

```
POST /contribuables/batch?creePar=admin HTTP/1.1
Content-Type: multipart/form-data; boundary=----boundary123

------boundary123
Content-Disposition: form-data; name="data"

[{"typeContribuable":"PP","nom":"Doe","telephone1":"0812345678","origineFiche":"mobile","refTypeActivite":1,...},{"typeContribuable":"PM","raisonSociale":"ACME SARL","telephone1":"0898765432","origineFiche":"mobile",...}]

------boundary123
Content-Disposition: form-data; name="files_0"; filename="piece_identite_john.pdf"
Content-Type: application/pdf

<contenu binaire du fichier>

------boundary123
Content-Disposition: form-data; name="files_0"; filename="attestation_john.jpg"
Content-Type: image/jpeg

<contenu binaire du fichier>

------boundary123
Content-Disposition: form-data; name="files_1"; filename="rccm_acme.pdf"
Content-Type: application/pdf

<contenu binaire du fichier>

------boundary123--
```

---

## Résumé

| Étape | Description |
|---|---|
| 1 | Construire la liste de `ContribuableDto` en Dart |
| 2 | Sérialiser la liste en JSON string |
| 3 | Créer un `MultipartRequest` vers `/contribuables/batch?creePar=xxx` |
| 4 | Ajouter le JSON dans le champ `data` |
| 5 | Pour chaque contribuable ayant des fichiers, ajouter les fichiers sous le nom `files_X` (X = index) |
| 6 | Envoyer la requête et traiter la réponse |

## Notes importantes

- **Android emulator** : utiliser `http://10.0.2.2:8020` (redirige vers `localhost` de la machine hôte)
- **Appareil physique** : utiliser l'adresse IP locale du PC (ex: `http://192.168.1.50:8020`)
- **iOS simulator** : utiliser `http://localhost:8020`
- Les dates doivent être au format **ISO 8601** : `2026-02-24T00:00:00.000Z`
- Les champs `typeContribuable`, `telephone1`, et `origineFiche` sont **obligatoires**
- Les `refTypeActivite`, `refZoneType`, `refAvenue`, `refQuartier`, `refCommune` sont des **IDs** qui doivent exister dans la base de données
- Chaque `files_X` peut contenir **plusieurs fichiers** pour un même contribuable

