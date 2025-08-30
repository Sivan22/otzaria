import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'measurement_data.dart';

// START OF ADDITIONS - MODERN UNITS
const List<String> modernLengthUnits = ['ס"מ', 'מטר', 'ק"מ'];
const List<String> modernAreaUnits = ['מ"ר', 'דונם'];
const List<String> modernVolumeUnits = ['סמ"ק', 'ליטר'];
const List<String> modernWeightUnits = ['גרם', 'ק"ג'];
// END OF ADDITIONS

class MeasurementConverterScreen extends StatefulWidget {
  const MeasurementConverterScreen({super.key});

  @override
  State<MeasurementConverterScreen> createState() =>
      _MeasurementConverterScreenState();
}

class _MeasurementConverterScreenState
    extends State<MeasurementConverterScreen> {
  String _selectedCategory = 'אורך';
  String? _selectedFromUnit;
  String? _selectedToUnit;
  String? _selectedOpinion;
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _resultController = TextEditingController();

  // Updated to include modern units
  final Map<String, List<String>> _units = {
    'אורך': lengthConversionFactors.keys.toList()..addAll(modernLengthUnits),
    'שטח': areaConversionFactors.keys.toList()..addAll(modernAreaUnits),
    'נפח': volumeConversionFactors.keys.toList()..addAll(modernVolumeUnits),
    'משקל': weightConversionFactors.keys.toList()..addAll(modernWeightUnits),
    'זמן': timeConversionFactors.keys.first.isNotEmpty
        ? timeConversionFactors[timeConversionFactors.keys.first]!.keys.toList()
        : [],
  };

  final Map<String, List<String>> _opinions = {
    'אורך': modernLengthFactors.keys.toList(),
    'שטח': modernAreaFactors.keys.toList(),
    'נפח': modernVolumeFactors.keys.toList(),
    'משקל': modernWeightFactors.keys.toList(),
    'זמן': timeConversionFactors.keys.toList(),
  };

  @override
  void initState() {
    super.initState();
    _resetDropdowns();
  }

  void _resetDropdowns() {
    setState(() {
      _selectedFromUnit = _units[_selectedCategory]!.first;
      _selectedToUnit = _units[_selectedCategory]!.first;
      _selectedOpinion = _opinions[_selectedCategory]?.first;
      _inputController.clear();
      _resultController.clear();
    });
  }

  // Helper function to handle small inconsistencies in unit names
  // e.g., 'אצבעות' vs 'אצבע', 'רביעיות' vs 'רביעית'
  String _normalizeUnitName(String unit) {
    const Map<String, String> normalizationMap = {
      'אצבעות': 'אצבע',
      'טפחים': 'טפח',
      'זרתות': 'זרת',
      'אמות': 'אמה',
      'קנים': 'קנה',
      'מילים': 'מיל',
      'פרסאות': 'פרסה',
      'בית רובע': 'בית רובע',
      'בית קב': 'בית קב',
      'בית סאה': 'בית סאה',
      'בית סאתיים': 'בית סאתיים',
      'בית לתך': 'בית לתך',
      'בית כור': 'בית כור',
      'רביעיות': 'רביעית',
      'לוגים': 'לוג',
      'קבים': 'קב',
      'עשרונות': 'עשרון',
      'הינים': 'הין',
      'סאים': 'סאה',
      'איפות': 'איפה',
      'לתכים': 'לתך',
      'כורים': 'כור',
      'דינרים': 'דינר',
      'שקלים': 'שקל',
      'סלעים': 'סלע',
      'טרטימרים': 'טרטימר',
      'מנים': 'מנה',
      'ככרות': 'כיכר',
      'קנטרים': 'קנטר',
    };
    return normalizationMap[unit] ?? unit;
  }

  // Core logic to get the conversion factor from any unit to a base modern unit
  double? _getFactorToBaseUnit(String category, String unit, String opinion) {
    final normalizedUnit = _normalizeUnitName(unit);

    switch (category) {
      case 'אורך': // Base unit: cm
        if (modernLengthUnits.contains(unit)) {
          if (unit == 'ס"מ') return 1.0;
          if (unit == 'מטר') return 100.0;
          if (unit == 'ק"מ') return 100000.0;
        } else {
          final value = modernLengthFactors[opinion]![normalizedUnit];
          if (value == null) return null;
          // Units in data are cm, m, km. Convert all to cm.
          if (['קנה', 'מיל'].contains(normalizedUnit))
            return value * 100; // m to cm
          if (['פרסה'].contains(normalizedUnit))
            return value * 100000; // km to cm
          return value; // Already in cm
        }
        break;
      case 'שטח': // Base unit: m^2
        if (modernAreaUnits.contains(unit)) {
          if (unit == 'מ"ר') return 1.0;
          if (unit == 'דונם') return 1000.0;
        } else {
          final value = modernAreaFactors[opinion]![normalizedUnit];
          if (value == null) return null;
          // Units in data are m^2, dunam. Convert all to m^2
          if (['בית סאתיים', 'בית לתך', 'בית כור'].contains(normalizedUnit) ||
              (opinion == 'חתם סופר' && normalizedUnit == 'בית סאה')) {
            return value * 1000; // dunam to m^2
          }
          return value; // Already in m^2
        }
        break;
      case 'נפח': // Base unit: cm^3
        if (modernVolumeUnits.contains(unit)) {
          if (unit == 'סמ"ק') return 1.0;
          if (unit == 'ליטר') return 1000.0;
        } else {
          final value = modernVolumeFactors[opinion]![normalizedUnit];
          if (value == null) return null;
          // Units in data are cm^3, L. Convert all to cm^3
          if (['קב', 'עשרון', 'הין', 'סאה', 'איפה', 'לתך', 'כור']
              .contains(normalizedUnit)) {
            return value * 1000; // L to cm^3
          }
          return value; // Already in cm^3
        }
        break;
      case 'משקל': // Base unit: g
        if (modernWeightUnits.contains(unit)) {
          if (unit == 'גרם') return 1.0;
          if (unit == 'ק"ג') return 1000.0;
        } else {
          final value = modernWeightFactors[opinion]![_normalizeUnitName(unit)];
          if (value == null) return null;
          // Units in data are g, kg. Convert all to g
          if (['כיכר', 'קנטר'].contains(normalizedUnit)) {
            return value * 1000; // kg to g
          }
          return value; // Already in g
        }
        break;
    }
    return null;
  }

  void _convert() {
    final double? input = double.tryParse(_inputController.text);
    if (input == null ||
        _selectedFromUnit == null ||
        _selectedToUnit == null ||
        _inputController.text.isEmpty) {
      setState(() {
        _resultController.clear();
      });
      return;
    }

    // Check if both units are ancient
    bool fromIsAncient = !(_units[_selectedCategory]!
        .sublist(_units[_selectedCategory]!.length - modernLengthUnits.length)
        .contains(_selectedFromUnit));
    bool toIsAncient = !(_units[_selectedCategory]!
        .sublist(_units[_selectedCategory]!.length - modernLengthUnits.length)
        .contains(_selectedToUnit));

    double result = 0.0;

    // ----- CONVERSION LOGIC -----
    if (_selectedCategory == 'זמן') {
      if (_selectedOpinion != null) {
        final fromFactor =
            timeConversionFactors[_selectedOpinion]![_selectedFromUnit]!;
        final toFactor =
            timeConversionFactors[_selectedOpinion]![_selectedToUnit]!;
        final conversionFactor = fromFactor / toFactor;
        result = input * conversionFactor;
      }
    } else if (fromIsAncient && toIsAncient) {
      // Case 1: Ancient to Ancient conversion (doesn't need opinion)
      double conversionFactor = 1.0;
      switch (_selectedCategory) {
        case 'אורך':
          conversionFactor =
              lengthConversionFactors[_selectedFromUnit]![_selectedToUnit]!;
          break;
        case 'שטח':
          conversionFactor =
              areaConversionFactors[_selectedFromUnit]![_selectedToUnit]!;
          break;
        case 'נפח':
          conversionFactor =
              volumeConversionFactors[_selectedFromUnit]![_selectedToUnit]!;
          break;
        case 'משקל':
          conversionFactor =
              weightConversionFactors[_selectedFromUnit]![_selectedToUnit]!;
          break;
      }
      result = input * conversionFactor;
    } else {
      // Case 2: Conversion involving any modern unit (requires an opinion)
      if (_selectedOpinion == null) {
        _resultController.text = "נא לבחור שיטה";
        return;
      }

      // Step 1: Convert input from 'FromUnit' to the base unit (e.g., cm for length)
      final factorFrom = _getFactorToBaseUnit(
          _selectedCategory, _selectedFromUnit!, _selectedOpinion!);
      if (factorFrom == null) {
        _resultController.clear();
        return;
      }
      final valueInBaseUnit = input * factorFrom;

      // Step 2: Convert the value from the base unit to the 'ToUnit'
      final factorTo = _getFactorToBaseUnit(
          _selectedCategory, _selectedToUnit!, _selectedOpinion!);
      if (factorTo == null) {
        _resultController.clear();
        return;
      }
      result = valueInBaseUnit / factorTo;
    }

    setState(() {
      if (result.isNaN || result.isInfinite) {
        _resultController.clear();
      } else {
        _resultController.text = result
            .toStringAsFixed(4)
            .replaceAll(RegExp(r'([.]*0+)(?!.*\d)'), '');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ממיר מידות תורני'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCategorySelector(),
              const SizedBox(height: 20),
              _buildUnitSelectors(),
              const SizedBox(height: 20),
              if (_opinions.containsKey(_selectedCategory) &&
                  _opinions[_selectedCategory]!.isNotEmpty)
                _buildOpinionSelector(),
              const SizedBox(height: 20),
              _buildInputField(),
              const SizedBox(height: 20),
              _buildResultDisplay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: const InputDecoration(
        labelText: 'קטגוריה',
        border: OutlineInputBorder(),
      ),
      items: _units.keys.map((String category) {
        return DropdownMenuItem<String>(
          value: category,
          child: Text(category),
        );
      }).toList(),
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            _selectedCategory = newValue;
            _resetDropdowns();
          });
        }
      },
    );
  }

  Widget _buildUnitSelectors() {
    return Row(
      children: [
        Expanded(
            child: _buildDropdown('מ', _selectedFromUnit, (val) {
          setState(() => _selectedFromUnit = val);
          _convert();
        })),
        const SizedBox(width: 10),
        IconButton(
          icon: const Icon(Icons.swap_horiz),
          onPressed: () {
            setState(() {
              final temp = _selectedFromUnit;
              _selectedFromUnit = _selectedToUnit;
              _selectedToUnit = temp;
              _convert();
            });
          },
        ),
        const SizedBox(width: 10),
        Expanded(
            child: _buildDropdown('אל', _selectedToUnit, (val) {
          setState(() => _selectedToUnit = val);
          _convert();
        })),
      ],
    );
  }

  Widget _buildDropdown(
      String label, String? value, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: _units[_selectedCategory]!.map((String unit) {
        return DropdownMenuItem<String>(
          value: unit,
          child: Text(unit, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  // A map to easily check if a unit is modern
  final Map<String, List<String>> _modernUnits = {
    'אורך': modernLengthUnits,
    'שטח': modernAreaUnits,
    'נפח': modernVolumeUnits,
    'משקל': modernWeightUnits,
  };

  Widget _buildOpinionSelector() {
    // Default to enabled
    bool isOpinionEnabled = true;

    // For categories other than 'זמן'
    if (_selectedCategory != 'זמן') {
      final moderns = _modernUnits[_selectedCategory] ?? [];
      final bool isFromModern = moderns.contains(_selectedFromUnit);
      final bool isToModern = moderns.contains(_selectedToUnit);

      // Disable ONLY if converting from ancient to ancient
      if (!isFromModern && !isToModern) {
        isOpinionEnabled = false;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _selectedOpinion,
          decoration: InputDecoration(
            labelText: 'שיטה',
            border: const OutlineInputBorder(),
            // Make the field gray if it's disabled
            filled: !isOpinionEnabled,
            fillColor: Colors.grey[200],
          ),
          items: _opinions[_selectedCategory]!.map((String opinion) {
            return DropdownMenuItem<String>(
              value: opinion,
              child: Text(opinion, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          // Set onChanged to null to disable the dropdown
          onChanged: isOpinionEnabled
              ? (String? newValue) {
                  setState(() {
                    _selectedOpinion = newValue;
                    _convert();
                  });
                }
              : null,
        ),
        // Show a helper text only when the dropdown is disabled
        if (!isOpinionEnabled)
          Padding(
            padding: const EdgeInsets.only(top: 4.0, right: 8.0),
            child: Text(
              'השיטה אינה רלוונטית להמרה בין מידות חז"ל.',
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              textAlign: TextAlign.right,
            ),
          ),
      ],
    );
  }

  Widget _buildInputField() {
    return TextField(
      controller: _inputController,
      decoration: const InputDecoration(
        labelText: 'ערך להמרה',
        border: OutlineInputBorder(),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      onChanged: (value) => _convert(),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.right,
    );
  }

  Widget _buildResultDisplay() {
    return TextField(
      controller: _resultController,
      readOnly: true,
      decoration: const InputDecoration(
        labelText: 'תוצאה',
        border: OutlineInputBorder(),
      ),
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.right,
    );
  }
}
