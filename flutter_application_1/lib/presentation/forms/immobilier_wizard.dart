import 'package:flutter/material.dart';
import '../../core/utils/success_popup.dart';
import '../../data/datasources/local/parcelle_local_datasource.dart';
import '../../data/datasources/local/contribuable_local_datasource.dart';
import '../../data/datasources/local/batiment_local_datasource.dart';
import '../../data/datasources/local/unite_local_datasource.dart';
import '../../data/models/entities/parcelle_entity.dart';
import '../../data/models/entities/contribuable_entity.dart';
import '../../data/models/entities/batiment_entity.dart';
import '../../data/models/entities/unite_entity.dart';
import '../forms/parcelle_form.dart';
import '../forms/contribuable_form.dart';
import '../forms/batiment_list_step.dart';

/// Immobilier Wizard - 3-step form for creating/editing Parcelle with Personne and Batiments
/// 
/// Step 1: Parcelle form
/// Step 2: Personne form (owner)
/// Step 3: Batiments list (0 or more buildings, each with 0 or more unités)
class ImmobilierWizard extends StatefulWidget {
  final int? parcelleId; // If provided, wizard is in edit mode
  final VoidCallback? onComplete;

  const ImmobilierWizard({
    super.key,
    this.parcelleId,
    this.onComplete,
  });

  @override
  State<ImmobilierWizard> createState() => _ImmobilierWizardState();
}

class _ImmobilierWizardState extends State<ImmobilierWizard> {
  final ParcelleLocalDatasource _parcelleDatasource = ParcelleLocalDatasource();
  final ContribuableLocalDatasource _contribuableDatasource = ContribuableLocalDatasource();
  final BatimentLocalDatasource _batimentDatasource = BatimentLocalDatasource();
  final UniteLocalDatasource _uniteDatasource = UniteLocalDatasource();

  int _currentStep = 0;
  bool _isLoading = false;
  bool _isLoadingData = false;

  // Form keys for each step
  final GlobalKey<ParcelleFormState> _parcelleFormKey = GlobalKey<ParcelleFormState>();
  final GlobalKey<ContribuableFormState> _contribuableFormKey = GlobalKey<ContribuableFormState>();
  final GlobalKey<BatimentListStepState> _batimentListKey = GlobalKey<BatimentListStepState>();

  // Data holders
  ParcelleEntity? _parcelle;
  ContribuableEntity? _contribuable;
  List<BatimentEntity> _batiments = [];
  Map<int, List<UniteEntity>> _unitesPerBatiment = {};

  // Existing IDs for edit mode
  int? _existingParcelleId;
  int? _existingContribuableId;
  List<int> _existingBatimentIds = [];
  // Map from batiment index to list of existing unite IDs
  Map<int, List<int>> _existingUniteIds = {};

  bool get _isEditing => widget.parcelleId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadExistingData();
    }
  }

  Future<void> _loadExistingData() async {
    setState(() => _isLoadingData = true);

    try {
      final details = await _parcelleDatasource.getParcelleWithDetails(widget.parcelleId!);
      if (details != null && mounted) {
        final parcelle = details['parcelle'] as ParcelleEntity;
        final contribuable = details['personne'] as ContribuableEntity?;
        final batiments = (details['batiments'] as List<BatimentEntity>?) ?? [];

        // Load unités for each batiment
        final unitesMap = <int, List<UniteEntity>>{};
        final existingUniteIdsMap = <int, List<int>>{};
        for (int i = 0; i < batiments.length; i++) {
          if (batiments[i].id != null) {
            final unites = await _uniteDatasource.getUnitesByBatimentId(batiments[i].id!);
            unitesMap[i] = unites;
            existingUniteIdsMap[i] = unites.where((u) => u.id != null).map((u) => u.id!).toList();
          }
        }

        setState(() {
          _parcelle = parcelle;
          _contribuable = contribuable;
          _batiments = batiments;
          _unitesPerBatiment = unitesMap;

          _existingParcelleId = _parcelle?.id;
          _existingContribuableId = _contribuable?.id;
          _existingBatimentIds = _batiments.map((b) => b.id!).toList();
          _existingUniteIds = existingUniteIdsMap;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de chargement: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    }
  }

  void _onStepContinue() {
    if (_currentStep == 0) {
      // Validate Parcelle form
      if (_parcelleFormKey.currentState?.validate() ?? false) {
        _parcelle = _parcelleFormKey.currentState!.getData();
        setState(() => _currentStep = 1);
      }
    } else if (_currentStep == 1) {
      // Validate Contribuable form
      if (_contribuableFormKey.currentState?.validate() ?? false) {
        _contribuable = _contribuableFormKey.currentState!.getData();
        setState(() => _currentStep = 2);
      }
    } else if (_currentStep == 2) {
      // Save all data
      _batiments = _batimentListKey.currentState?.getData() ?? [];
      _unitesPerBatiment = _batimentListKey.currentState?.getUnitesData() ?? {};
      _saveAllData();
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      // Save current step data before going back
      if (_currentStep == 1) {
        _contribuable = _contribuableFormKey.currentState?.getData();
      } else if (_currentStep == 2) {
        _batiments = _batimentListKey.currentState?.getData() ?? [];
        _unitesPerBatiment = _batimentListKey.currentState?.getUnitesData() ?? {};
      }
      setState(() => _currentStep -= 1);
    } else {
      Navigator.pop(context);
    }
  }

  void _onStepTapped(int step) {
    // Save current form data before switching
    if (_currentStep == 0) {
      if (_parcelleFormKey.currentState?.validate() ?? false) {
        _parcelle = _parcelleFormKey.currentState!.getData();
      } else if (step > 0) {
        return; // Don't allow skipping invalid step
      }
    } else if (_currentStep == 1) {
      if (_contribuableFormKey.currentState?.validate() ?? false) {
        _contribuable = _contribuableFormKey.currentState!.getData();
      } else if (step > 1) {
        return;
      }
    } else if (_currentStep == 2) {
      _batiments = _batimentListKey.currentState?.getData() ?? [];
      _unitesPerBatiment = _batimentListKey.currentState?.getUnitesData() ?? {};
    }

    setState(() => _currentStep = step);
  }

  Future<void> _saveAllData() async {
    if (_parcelle == null || _contribuable == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Données incomplètes')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      int parcelleId;

      if (_isEditing && _existingParcelleId != null) {
        // Update existing parcelle
        final updatedParcelle = _parcelle!.copyWith(
          id: _existingParcelleId,
          dateMiseAJour: DateTime.now(),
        );
        await _parcelleDatasource.updateParcelle(updatedParcelle);
        parcelleId = _existingParcelleId!;
      } else {
        // Insert new parcelle
        parcelleId = await _parcelleDatasource.insertParcelle(_parcelle!);
      }

      // Handle Contribuable
      final contribuableWithParcelleId = _contribuable!.copyWith(
        id: _existingContribuableId,
        parcelleId: parcelleId,
      );
      
      if (_existingContribuableId != null) {
        await _contribuableDatasource.updateContribuable(contribuableWithParcelleId);
      } else {
        await _contribuableDatasource.insertContribuable(contribuableWithParcelleId);
      }

      // Handle Batiments and Unités
      // Delete removed batiments (cascade will delete their unités)
      final currentBatimentIds = _batiments
          .where((b) => b.id != null)
          .map((b) => b.id!)
          .toList();
      for (final oldId in _existingBatimentIds) {
        if (!currentBatimentIds.contains(oldId)) {
          await _batimentDatasource.deleteBatiment(oldId);
        }
      }

      // Insert or update batiments and their unités
      for (int i = 0; i < _batiments.length; i++) {
        final batiment = _batiments[i];
        final batimentWithParcelleId = batiment.copyWith(parcelleId: parcelleId);
        int batimentId;

        if (batiment.id != null && _existingBatimentIds.contains(batiment.id)) {
          await _batimentDatasource.updateBatiment(batimentWithParcelleId);
          batimentId = batiment.id!;
        } else {
          batimentId = await _batimentDatasource.insertBatiment(batimentWithParcelleId);
        }

        // Handle unités for this batiment
        final unites = _unitesPerBatiment[i] ?? [];
        
        // Find the original batiment index to get existing unite IDs
        int? originalIndex;
        if (batiment.id != null) {
          originalIndex = _existingBatimentIds.indexOf(batiment.id!);
          if (originalIndex == -1) originalIndex = null;
        }
        final existingIds = originalIndex != null ? (_existingUniteIds[originalIndex] ?? []) : <int>[];

        // Delete removed unités
        final currentUniteIds = unites
            .where((u) => u.id != null)
            .map((u) => u.id!)
            .toList();
        for (final oldUniteId in existingIds) {
          if (!currentUniteIds.contains(oldUniteId)) {
            await _uniteDatasource.deleteUnite(oldUniteId);
          }
        }

        // Insert or update unités
        for (final unite in unites) {
          // Persist locataire as a ContribuableEntity if present
          int? locataireContribuableId = unite.contribuableId;
          if (unite.locataire != null) {
            final locataireEntity = unite.locataire!.copyWith(
              updatedAt: DateTime.now(),
            );
            if (locataireEntity.id != null) {
              await _contribuableDatasource.updateContribuable(locataireEntity);
              locataireContribuableId = locataireEntity.id;
            } else {
              locataireContribuableId = await _contribuableDatasource.insertContribuable(locataireEntity);
            }
          }

          final uniteWithIds = unite.copyWith(
            batimentId: batimentId,
            contribuableId: locataireContribuableId,
          );
          if (unite.id != null && existingIds.contains(unite.id)) {
            await _uniteDatasource.updateUnite(uniteWithIds);
          } else {
            await _uniteDatasource.insertUnite(uniteWithIds);
          }
        }
      }

      if (mounted) {
        if (_isEditing) {
          await SuccessPopup.showUpdateSuccess(context, itemName: 'La parcelle');
        } else {
          await SuccessPopup.showAddSuccess(context, itemName: 'La parcelle');
        }
        widget.onComplete?.call();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Modifier Parcelle' : 'Nouvelle Parcelle'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier Parcelle' : 'Nouvelle Parcelle'),
      ),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        onStepContinue: _isLoading ? null : _onStepContinue,
        onStepCancel: _isLoading ? null : _onStepCancel,
        onStepTapped: _isLoading ? null : _onStepTapped,
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : details.onStepCancel,
                      child: const Text('Précédent'),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : details.onStepContinue,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_currentStep == 2 
                            ? (_isEditing ? 'Mettre à jour' : 'Enregistrer')
                            : 'Suivant'),
                  ),
                ),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Parcelle'),
            subtitle: _parcelle != null 
                ? Text(_parcelle!.commune ?? 'Parcelle')
                : null,
            content: ParcelleForm(
              key: _parcelleFormKey,
              parcelle: _parcelle,
              showAppBar: false,
              onSave: (parcelle) {
                _parcelle = parcelle;
              },
            ),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 
                ? StepState.complete 
                : (_currentStep == 0 ? StepState.editing : StepState.indexed),
          ),
          Step(
            title: const Text('Propriétaire'),
            subtitle: _contribuable != null 
                ? Text(_contribuable!.displayName)
                : null,
            content: ContribuableForm(
              key: _contribuableFormKey,
              contribuable: _contribuable,
              showAppBar: false,
              onSave: (contribuable) {
                _contribuable = contribuable;
              },
            ),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 
                ? StepState.complete 
                : (_currentStep == 1 ? StepState.editing : StepState.indexed),
          ),
          Step(
            title: const Text('Bâtiments'),
            subtitle: Text('${_batiments.length} bâtiment(s)'),
            content: BatimentListStep(
              key: _batimentListKey,
              batiments: _batiments,
              unitesPerBatiment: _unitesPerBatiment,
              onBatimentsChanged: (batiments) {
                _batiments = batiments;
              },
              onUnitesChanged: (unitesMap) {
                _unitesPerBatiment = unitesMap;
              },
            ),
            isActive: _currentStep >= 2,
            state: _currentStep == 2 ? StepState.editing : StepState.indexed,
          ),
        ],
      ),
    );
  }
}
