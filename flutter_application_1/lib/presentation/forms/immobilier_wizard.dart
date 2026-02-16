import 'package:flutter/material.dart';
import '../../core/utils/success_popup.dart';
import '../../data/datasources/local/parcelle_local_datasource.dart';
import '../../data/datasources/local/personne_local_datasource.dart';
import '../../data/datasources/local/batiment_local_datasource.dart';
import '../../data/models/entities/parcelle_entity.dart';
import '../../data/models/entities/personne_entity.dart';
import '../../data/models/entities/batiment_entity.dart';
import '../forms/parcelle_form.dart';
import '../forms/personne_form.dart';
import '../forms/batiment_list_step.dart';

/// Immobilier Wizard - 3-step form for creating/editing Parcelle with Personne and Batiments
/// 
/// Step 1: Parcelle form
/// Step 2: Personne form (owner)
/// Step 3: Batiments list (0 or more buildings)
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
  final PersonneLocalDatasource _personneDatasource = PersonneLocalDatasource();
  final BatimentLocalDatasource _batimentDatasource = BatimentLocalDatasource();

  int _currentStep = 0;
  bool _isLoading = false;
  bool _isLoadingData = false;

  // Form keys for each step
  final GlobalKey<ParcelleFormState> _parcelleFormKey = GlobalKey<ParcelleFormState>();
  final GlobalKey<PersonneFormState> _personneFormKey = GlobalKey<PersonneFormState>();
  final GlobalKey<BatimentListStepState> _batimentListKey = GlobalKey<BatimentListStepState>();

  // Data holders
  ParcelleEntity? _parcelle;
  PersonneEntity? _personne;
  List<BatimentEntity> _batiments = [];

  // Existing IDs for edit mode
  int? _existingParcelleId;
  int? _existingPersonneId;
  List<int> _existingBatimentIds = [];

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
        setState(() {
          _parcelle = details['parcelle'] as ParcelleEntity;
          _personne = details['personne'] as PersonneEntity?;
          _batiments = (details['batiments'] as List<BatimentEntity>?) ?? [];
          
          _existingParcelleId = _parcelle?.id;
          _existingPersonneId = _personne?.id;
          _existingBatimentIds = _batiments.map((b) => b.id!).toList();
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
      // Validate Personne form
      if (_personneFormKey.currentState?.validate() ?? false) {
        _personne = _personneFormKey.currentState!.getData();
        setState(() => _currentStep = 2);
      }
    } else if (_currentStep == 2) {
      // Save all data
      _batiments = _batimentListKey.currentState?.getData() ?? [];
      _saveAllData();
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      // Save current step data before going back
      if (_currentStep == 1) {
        _personne = _personneFormKey.currentState?.getData();
      } else if (_currentStep == 2) {
        _batiments = _batimentListKey.currentState?.getData() ?? [];
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
      if (_personneFormKey.currentState?.validate() ?? false) {
        _personne = _personneFormKey.currentState!.getData();
      } else if (step > 1) {
        return;
      }
    } else if (_currentStep == 2) {
      _batiments = _batimentListKey.currentState?.getData() ?? [];
    }

    setState(() => _currentStep = step);
  }

  Future<void> _saveAllData() async {
    if (_parcelle == null || _personne == null) {
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

      // Handle Personne
      final personneWithParcelleId = _personne!.copyWith(
        id: _existingPersonneId,
        parcelleId: parcelleId,
      );
      
      if (_existingPersonneId != null) {
        await _personneDatasource.updatePersonne(personneWithParcelleId);
      } else {
        await _personneDatasource.insertPersonne(personneWithParcelleId);
      }

      // Handle Batiments
      // Delete removed batiments
      final currentBatimentIds = _batiments
          .where((b) => b.id != null)
          .map((b) => b.id!)
          .toList();
      for (final oldId in _existingBatimentIds) {
        if (!currentBatimentIds.contains(oldId)) {
          await _batimentDatasource.deleteBatiment(oldId);
        }
      }

      // Insert or update batiments
      for (final batiment in _batiments) {
        final batimentWithParcelleId = batiment.copyWith(parcelleId: parcelleId);
        if (batiment.id != null && _existingBatimentIds.contains(batiment.id)) {
          await _batimentDatasource.updateBatiment(batimentWithParcelleId);
        } else {
          await _batimentDatasource.insertBatiment(batimentWithParcelleId);
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
            subtitle: _personne != null 
                ? Text(_personne!.displayName)
                : null,
            content: PersonneForm(
              key: _personneFormKey,
              personne: _personne,
              showAppBar: false,
              onSave: (personne) {
                _personne = personne;
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
              onBatimentsChanged: (batiments) {
                _batiments = batiments;
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
