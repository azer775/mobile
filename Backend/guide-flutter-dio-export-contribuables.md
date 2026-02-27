# Flutter Dio Export Plan for Batch Contribuables

## Goal
Export a batch of contribuables from local SQLite to:

- Endpoint: POST /contribuables/batch
- Content-Type: multipart/form-data
- Body parts:
  - data: JSON array of contribuables
  - files_0, files_1, files_2, ...: files attached to each contribuable by index

This guide focuses only on exporting and API consumption.

---

## 1) Attribute Contract (How fields must be written)

The backend expects field names exactly as in ContribuableDto (camelCase).

### Required in practice (to avoid DB errors)

At minimum, each object in data should include:

- typeContribuable (String)
- telephone1 (String)
- origineFiche (String)

These correspond to non-null columns in the backend entity.

### Full supported fields

Each contribuable JSON object can contain:

- nif: String
- typeNif: String
- typeContribuable: String
- nom: String
- postNom: String
- prenom: String
- raisonSociale: String
- telephone1: String
- telephone2: String
- email: String
- rue: String
- numeroParcelle: String
- origineFiche: String
- statut: Integer
- gpsLatitude: Double
- gpsLongitude: Double
- pieceIdentiteUrl: String
- dateInscription: String (ISO-8601 Instant, example: 2026-02-25T10:00:00Z)
- dateMaj: String (ISO-8601 Instant)
- formeJuridique: String
- numeroRccm: String
- refTypeActivite: Integer
- refZoneType: Integer
- refAvenue: Integer
- refQuartier: Integer
- refCommune: Integer

### Important naming rules

- Use camelCase exactly (example: typeContribuable, not type_contribuable).
- Do not rename keys.
- Do not nest the object under another key (send plain array in data).
- Keep numbers as numbers (not quoted text) for Integer/Double fields.

---

## 2) Index Mapping Rules for Files

For a batch with N contribuables:

- data[0] -> files must be sent under files_0
- data[1] -> files must be sent under files_1
- data[2] -> files must be sent under files_2
- etc.

If one contribuable has multiple photos, repeat the same key:

- files_0 = photoA
- files_0 = photoB
- files_0 = photoC

No file is also valid (just omit files_i).

---

## 3) Recommended Export Algorithm (SQLite -> Dio)

1. Read unsynced contribuables in stable order (created_at ASC, id ASC).
2. Create ordered dtoList from that query.
3. For each index i in dtoList, get attached files from local storage.
4. Build FormData:
   - add one text field data = jsonEncode(dtoList)
   - append each file under files_i
5. POST multipart to /contribuables/batch.
6. If HTTP 200: mark that exact batch as synced.
7. Else: mark failed and keep retry metadata.

Use chunking (example: 20 contribuables per request) for reliability.

---

## 4) Dio Implementation Blueprint

```dart
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

class BatchExportItem {
  final Map<String, dynamic> dto;
  final List<String> filePaths;
  final int localId;

  BatchExportItem({
    required this.dto,
    required this.filePaths,
    required this.localId,
  });
}

class DioContribuableExporter {
  final Dio dio;
  final String baseUrl;

  DioContribuableExporter({required this.dio, required this.baseUrl});

  Future<Response<dynamic>> exportBatch(List<BatchExportItem> batch) async {
    final formData = FormData();

    // 1) JSON array in part: data
    final dtoList = batch.map((e) => e.dto).toList();
    formData.fields.add(MapEntry('data', jsonEncode(dtoList)));

    // 2) Files per index: files_0, files_1, ...
    for (int i = 0; i < batch.length; i++) {
      final key = 'files_$i';
      for (final path in batch[i].filePaths) {
        final file = File(path);
        if (!await file.exists()) continue;

        formData.files.add(
          MapEntry(
            key,
            await MultipartFile.fromFile(
              path,
              filename: p.basename(path),
            ),
          ),
        );
      }
    }

    return dio.post(
      '$baseUrl/contribuables/batch',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        validateStatus: (status) => status != null && status >= 200 && status < 500,
      ),
    );
  }
}
```

---

## 5) Success and Failure Handling

### Success condition

Treat as success only when:

- response.statusCode == 200

Then mark exported local records as synced.

### Failure condition

Any non-200 should be treated as failed export for that batch.

Store:

- error message (response body or DioException)
- attempt count
- last attempt timestamp

Retry only transient failures (timeouts, socket, HTTP 5xx).

---

## 6) Known Safe Payload Example

This structure is confirmed working with the backend:

```json
[
  {
    "typeContribuable": "PP",
    "nom": "Test0",
    "telephone1": "09990001",
    "origineFiche": "mobile"
  },
  {
    "typeContribuable": "PM",
    "raisonSociale": "Company1",
    "telephone1": "09990002",
    "origineFiche": "mobile"
  }
]
```

And multipart files:

- files_0: photo1.jpg
- files_0: photo2.jpg
- files_1: photo3.jpg

---

## 7) Final Checklist Before Go-Live

- Field names match ContribuableDto exactly.
- Required fields are present for every row.
- Index alignment between data[i] and files_i is correct.
- File path exists before attaching.
- Batch size is limited (10 to 30 recommended).
- Only one export job runs at a time.
