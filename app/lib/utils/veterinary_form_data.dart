import 'package:flutter/material.dart';

class VetEntry {
  final String title;
  final String subtitle;
  final Map<String, dynamic> payload;

  final Map<String, dynamic> meta;

  VetEntry({
    required this.title,
    required this.subtitle,
    required this.payload,
    Map<String, dynamic>? meta,
  }) : meta = meta ?? <String, dynamic>{};
}

class VeterinaryFormData {
  final TextEditingController sizeController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  bool neutered = false;

  final List<VetEntry> vaccinations = [];
  final List<VetEntry> surgeries = [];
  final List<VetEntry> preventives = [];
  final List<VetEntry> labTests = [];
  final List<VetEntry> diagnoses = [];
  final List<VetEntry> treatments = [];

  int _nextLocalId = 1;
  int newLocalId() => _nextLocalId++;

  final Map<int, int> savedDiagnosisIds = {};

  bool get hasItems =>
      vaccinations.isNotEmpty ||
      surgeries.isNotEmpty ||
      preventives.isNotEmpty ||
      labTests.isNotEmpty ||
      diagnoses.isNotEmpty ||
      treatments.isNotEmpty;

  Map<String, dynamic> recordPayload() {
    final size = int.tryParse(sizeController.text.trim());
    final weight = double.tryParse(
      weightController.text.trim().replaceAll(',', '.'),
    );

    return {
      'neutered': neutered,
      if (size != null) 'size': size,
      if (weight != null) 'weight': weight,
    };
  }

  void dispose() {
    sizeController.dispose();
    weightController.dispose();
  }
}
