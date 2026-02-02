## Plan: JWT Authentication & Data Export with Multipart Photo Upload

Implement automatic authentication with saved credentials, export contribuables with photos as multipart, and reseed reference tables on success.

### Steps

1. **Update API configuration** in [lib/core/constants/api_constants.dart](lib/core/constants/api_constants.dart)
   - Add base URL, login endpoint (`/auth/login`), export endpoint (`/contribuables/export`)
   - Configure multipart field names (JSON data field, photo files field)

2. **Create `TokenService`** in [lib/core/services/token_service.dart](lib/core/services/)
   - Use `flutter_secure_storage` (already installed) for secure JWT storage
   - `saveToken(String token)`: Store JWT token securely
   - `getToken()`: Retrieve stored JWT token
   - `clearToken()`: Remove JWT token on logout or expiry
   - `hasToken()`: Check if a valid token exists

3. **Add multipart upload support** to [lib/core/services/api_client.dart](lib/core/services/api_client.dart)
   - Create `postMultipart()` method using `http.MultipartRequest`
   - Handle `http.MultipartFile.fromPath()` for photo files
   - Include `Authorization: Bearer <token>` header
   - Add method to load token from `TokenService` on initialization

4. **Create `ExportService`** in [lib/core/services/export_service.dart](lib/core/services/)
   - `authenticate()`: POST credentials from `SecretCredentialsService` → get JWT → store via `TokenService`
   - `exportContribuables(List<ContribuableEntity>)`: Load token from `TokenService`, send multipart request with JSON + photos
   - `onExportSuccess()`: Call `deleteAllData()` then `insertAll()` for ref tables, clear token
   - `export()`: Orchestrate full flow (auth → store token → export → cleanup → reseed → clear token)

5. **Add helper methods** to datasources
   - Add `getAll()` in [contribuable_local_datasource.dart](lib/data/datasources/local/contribuable_local_datasource.dart) (already exists as `getAllContribuables`)
   - Verify `insertAll()` exists in both ref datasources (already added)
   - Verify `deleteAllData()` exists in [database_helper.dart](lib/data/datasources/local/database_helper.dart) (already added)

5. **Create predefined reference data** in [lib/core/constants/reference_data.dart](lib/core/constants/)
   - Hardcoded list of `RefTypeActiviteEntity` with id + libelle
   - Hardcoded list of `RefZoneTypeEntity` with id + libelle

6. **Update export button** in [lib/presentation/pages/contribuables_page.dart](lib/presentation/pages/contribuables_page.dart)
   - Replace `_exportContribuables()` to call `ExportService.export()`
   - Show loading dialog during export
   - Show success popup with count of exported records
   - Show error dialog if export fails (keep local data intact)

### Further Considerations

1. **Please provide your backend details:**
   - Base URL: `https://...`
   - Login request format: `{ "email": "...", "password": "..." }` or different?
   - Login response format: `{ "token": "..." }` or nested like `{ "data": { "accessToken": "..." } }`?
   - Export endpoint path: `/contribuables/export` or different?
   - Multipart field name for JSON: `data`, `contribuables`, or?
   - Multipart field name for photos: `photos`, `files`, `images`, or?

2. **Please provide reference data lists:**
   ```
   RefTypeActivite:
   - id: 1, libelle: "?"
   - id: 2, libelle: "?"
   - ...
   
   RefZoneType:
   - id: 1, libelle: "?"
   - id: 2, libelle: "?"
   - ...
   ```

3. **Photo handling during export:**
   - Should each contribuable's photos be sent with a unique identifier linking them?
   - What if a contribuable has no photos - skip or send empty?
