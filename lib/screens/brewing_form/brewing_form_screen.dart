import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:flowstate/models/coffee.dart';
import 'package:flowstate/models/brewing.dart';
import 'package:flowstate/models/brewing_step.dart';
import 'package:flowstate/services/database_service.dart';
import 'package:flowstate/widgets/star_rating_input.dart';

class BrewingFormScreen extends StatefulWidget {
  final Coffee coffee;
  final Brewing? brewing;

  const BrewingFormScreen({
    super.key,
    required this.coffee,
    this.brewing,
  });

  @override
  State<BrewingFormScreen> createState() => _BrewingFormScreenState();
}

class _BrewingFormScreenState extends State<BrewingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late TextEditingController _doseController;
  late TextEditingController _grindSettingController;
  late TextEditingController _tempController;
  late TextEditingController _preInfusionTimeController;
  late TextEditingController _preInfusionWaterController;
  late TextEditingController _totalTimeMinController;
  late TextEditingController _totalTimeSecController;
  late TextEditingController _notesController;
  
  int _rating = 3;
  List<TextEditingController> _pourControllers = [];

  @override
  void initState() {
    super.initState();
    final brewing = widget.brewing;

    _doseController = TextEditingController(text: brewing?.coffeeDose.toString() ?? '18');
    _grindSettingController = TextEditingController(text: brewing?.grindSetting ?? '');
    _tempController = TextEditingController(text: brewing?.waterTemperature.toString() ?? '94');
    _preInfusionTimeController = TextEditingController(text: brewing?.preInfusionTime?.toString() ?? '45');
    _preInfusionWaterController = TextEditingController(text: brewing?.preInfusionWater?.toString() ?? '50');
    
    final totalMinutes = brewing?.totalBrewTime.inMinutes.toString() ?? '2';
    final totalSeconds = (brewing?.totalBrewTime.inSeconds ?? 165) % 60;
    _totalTimeMinController = TextEditingController(text: totalMinutes);
    _totalTimeSecController = TextEditingController(text: totalSeconds.toString().padLeft(2, '0'));

    _notesController = TextEditingController(text: brewing?.notes ?? '');
    _rating = brewing?.rating ?? 3;

    if (brewing != null && brewing.steps.isNotEmpty) {
      _pourControllers = brewing.steps.map((step) => TextEditingController(text: step.waterAmount.toString())).toList();
    } else {

      _pourControllers = [
        TextEditingController(text: '60'),
        TextEditingController(text: '60'),
        TextEditingController(text: '60'),
      ];
    }
  }

  @override
  void dispose() {
    _doseController.dispose();
    _grindSettingController.dispose();
    _tempController.dispose();
    _preInfusionTimeController.dispose();
    _preInfusionWaterController.dispose();
    _totalTimeMinController.dispose();
    _totalTimeSecController.dispose();
    _notesController.dispose();
    for (var controller in _pourControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addPour() {
    setState(() {
      _pourControllers.add(TextEditingController());
    });
  }

  void _removePour(int index) {
    setState(() {
      _pourControllers[index].dispose();
      _pourControllers.removeAt(index);
    });
  }

  Future<void> _saveBrewing() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final totalMinutes = int.tryParse(_totalTimeMinController.text) ?? 0;
        final totalSeconds = int.tryParse(_totalTimeSecController.text) ?? 0;
        final totalDuration = Duration(minutes: totalMinutes, seconds: totalSeconds);

        final steps = _pourControllers.asMap().entries.map((entry) {
          return BrewingStep(
            stepNumber: entry.key + 1,
            waterAmount: double.tryParse(entry.value.text) ?? 0,
          );
        }).toList();

        if (widget.brewing == null) {
          final newBrewing = Brewing(
            id: const Uuid().v4(),
            coffeeId: widget.coffee.id,
            coffeeDose: double.parse(_doseController.text),
            grindSetting: _grindSettingController.text,
            waterTemperature: double.parse(_tempController.text),
            preInfusionTime: int.tryParse(_preInfusionTimeController.text),
            preInfusionWater: double.tryParse(_preInfusionWaterController.text),
            totalBrewTime: totalDuration,
            steps: steps,
            rating: _rating,
            notes: _notesController.text,
            brewDate: DateTime.now(),
          );
          await context.read<DatabaseService>().addBrewing(newBrewing);
        } else {
          final updatedBrewing = widget.brewing!.copyWith(
            coffeeDose: double.parse(_doseController.text),
            grindSetting: _grindSettingController.text,
            waterTemperature: double.parse(_tempController.text),
            preInfusionTime: int.tryParse(_preInfusionTimeController.text),
            preInfusionWater: double.tryParse(_preInfusionWaterController.text),
            totalBrewTime: totalDuration,
            steps: steps,
            rating: _rating,
            notes: _notesController.text,
          );
          await context.read<DatabaseService>().updateBrewing(updatedBrewing);
        }

        if (mounted) Navigator.pop(context);

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving brewing: $e')),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.brewing == null ? 'Add Brewing' : 'Edit Brewing'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Parameters'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildTextFormField(_doseController, 'Dose (g)', Icons.coffee)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextFormField(_grindSettingController, 'Grind', Icons.grain)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextFormField(_tempController, 'Temp (°C)', Icons.thermostat)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Pre-infusion (Bloom)'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildTextFormField(_preInfusionWaterController, 'Water (ml)', Icons.water_drop_outlined)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextFormField(_preInfusionTimeController, 'Time (s)', Icons.timer_outlined)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Pours'),
                    ..._buildPourFields(),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _addPour,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Pour'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Time & Notes'),
                    const SizedBox(height: 16),
                    _buildTotalTime(),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes & Thoughts',
                        hintText: 'e.g., "A bit bitter, try coarser grind next time."',
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Rating'),
                    const SizedBox(height: 8),
                    Center(
                      child: StarRatingInput(
                        rating: _rating,
                        onRatingChanged: (rating) => setState(() => _rating = rating),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
    );
  }

  Widget _buildTextFormField(TextEditingController controller, String label, IconData icon) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Required';
        }
        return null;
      },
    );
  }

  List<Widget> _buildPourFields() {
    return List.generate(_pourControllers.length, (index) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _pourControllers[index],
                decoration: InputDecoration(
                  labelText: 'Pour ${index + 1} (ml)',
                  prefixIcon: const Icon(Icons.water_drop, size: 20),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () => _removePour(index),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTotalTime() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(Icons.timer, color: Colors.grey),
        const SizedBox(width: 16),
        const Text('Total Time:', style: TextStyle(fontSize: 16)),
        const Spacer(),
        SizedBox(
          width: 60,
          child: TextFormField(
            controller: _totalTimeMinController,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(hintText: 'MM'),
            keyboardType: TextInputType.number,
          ),
        ),
        const Text(':', style: TextStyle(fontSize: 24)),
        SizedBox(
          width: 60,
          child: TextFormField(
            controller: _totalTimeSecController,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(hintText: 'SS'),
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade300,
              foregroundColor: Colors.black87,
            ),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _saveBrewing,
            child: const Text('Save'),
          ),
        ),
      ],
    );
  }
}