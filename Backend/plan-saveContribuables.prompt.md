## Plan : Fonction de sauvegarde batch de ContribuableDtos

Créer une méthode `saveContribuables` dans [ContribuableService.java](c:\Users\azerb\Desktop\mobile\Backend\src\main\java\org\example\backend\services\ContribuableService.java) qui prend une `List<ContribuableDto>`, sauvegarde les fichiers (`MultipartFile`) sur le disque, convertit chaque DTO en entité `Contribuable` (avec résolution des références par ID), et persiste le tout en base de données.

### Steps

1. **Ajouter une propriété de configuration de stockage** dans [application.properties](c:\Users\azerb\Desktop\mobile\Backend\src\main\resources\application.properties) — définir un chemin `file.upload-dir` pour le répertoire de destination des fichiers uploadés.

2. **Injecter les repositories de références** dans [ContribuableService.java](c:\Users\azerb\Desktop\mobile\Backend\src\main\java\org\example\backend\services\ContribuableService.java) — ajouter `@Autowired` pour `RefTypeActiviteRepository`, `RefZoneTypeRepository`, `RefAvenueRepository`, `RefQuartierRepository` et `RefCommuneRepository` afin de résoudre les ID en entités.

3. **Créer une méthode privée `saveFile(MultipartFile)`** dans `ContribuableService` — générer un nom unique (UUID + nom original), écrire le fichier dans le répertoire configuré via `Files.copy`, et retourner le chemin/URL du fichier sauvegardé.

4. **Créer la méthode publique `saveContribuables(List<ContribuableDto>)`** dans `ContribuableService` — itérer sur chaque DTO, mapper les champs scalaires vers une nouvelle entité `Contribuable`, résoudre les relations `@ManyToOne` via `findById` sur chaque repository de référence (avec les Integer IDs du DTO : `refTypeActivite`, `refZoneType`, `refAvenue`, `refQuartier`, `refCommune`), sauvegarder les `MultipartFile` du champ `documents` via `saveFile` et créer les entités `Document` correspondantes avec l'URL résultante, puis persister avec `contribuableRepository.saveAll`.

5. **Annoter la méthode avec `@Transactional`** pour garantir l'atomicité de l'opération batch (rollback si un fichier ou une entité échoue).

### Further Considerations

1. **Gestion d'erreurs fichiers** — Faut-il supprimer les fichiers déjà sauvegardés en cas d'échec partiel (rollback manuel) ? Ou accepter des fichiers orphelins ?
2. **Identifiant du `Document`** — L'entité `Document` n'a pas de `@GeneratedValue` sur son `@Id`. Il faudrait soit ajouter `@GeneratedValue(strategy = GenerationType.IDENTITY)`, soit gérer manuellement l'attribution des IDs.
3. **Exposition via contrôleur** — Souhaitez-vous aussi un endpoint REST (ex. `POST /api/contribuables`) avec `@RequestParam List<MultipartFile>` pour appeler cette méthode ?

