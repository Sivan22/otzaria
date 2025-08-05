import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'measurement_data.dart';

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

  final Map<String, List<String>> _units = {
    'אורך': lengthConversionFactors.keys.toList(),
    'שטח': areaConversionFactors.keys.toList(),
    'נפח': volumeConversionFactors.keys.toList(),
    'משקל': weightConversionFactors.keys.toList(),
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
      case 'זמן':
        if (_selectedOpinion != null) {
          final fromFactor =
              timeConversionFactors[_selectedOpinion]![_selectedFromUnit]!;
          final toFactor =
              timeConversionFactors[_selectedOpinion]![_selectedToUnit]!;
          conversionFactor = fromFactor / toFactor;
        }
        break;
    }

    setState(() {
      final result = input * conversionFactor;
      _resultController.text = result.toStringAsFixed(4);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ממיר מידות'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
        const Icon(Icons.arrow_forward),
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
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: _units[_selectedCategory]!.map((String unit) {
        return DropdownMenuItem<String>(
          value: unit,
          child: Text(unit),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildOpinionSelector() {
    return DropdownButtonFormField<String>(
      value: _selectedOpinion,
      decoration: const InputDecoration(
        labelText: 'שיטה',
        border: OutlineInputBorder(),
      ),
      items: _opinions[_selectedCategory]!.map((String opinion) {
        return DropdownMenuItem<String>(
          value: opinion,
          child: Text(opinion),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedOpinion = newValue;
          _convert();
        });
      },
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
    );
  }
}
