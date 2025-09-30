import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flowstate/models/coffee.dart';
import 'package:flowstate/services/database_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class CoffeeFormScreen extends StatefulWidget {
  final Coffee? coffee;

  const CoffeeFormScreen({super.key, this.coffee});

  @override
  State<CoffeeFormScreen> createState() => _CoffeeFormScreenState();
}

class _CoffeeFormScreenState extends State<CoffeeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _roasterController;
  late TextEditingController _originController;
  late TextEditingController _flavorProfileController;
  DateTime? _roastDate;
  String? _imageUrl;
  File? _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.coffee?.name ?? '');
    _roasterController = TextEditingController(text: widget.coffee?.roaster ?? '');
    _originController = TextEditingController(text: widget.coffee?.origin ?? '');
    _flavorProfileController = TextEditingController(text: widget.coffee?.flavorProfile ?? '');
    _roastDate = widget.coffee?.roastDate;
    _imageUrl = widget.coffee?.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roasterController.dispose();
    _originController.dispose();
    _flavorProfileController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final appDir = await getApplicationDocumentsDirectory();
    final fileName = p.basename(picked.path);
    final savedImage = await File(picked.path).copy('${appDir.path}/$fileName');

    setState(() {
      _imageFile = savedImage;
      _imageUrl = savedImage.path;
    });
  }

  Future<void> _selectRoastDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _roastDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _roastDate) {
      setState(() {
        _roastDate = picked;
      });
    }
  }

  Future<void> _saveCoffee() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        if (widget.coffee == null) {
          final newCoffee = Coffee(
            id: '', 
            name: _nameController.text,
            roaster: _roasterController.text,
            origin: _originController.text,
            flavorProfile: _flavorProfileController.text,
            roastDate: _roastDate,
            createdAt: DateTime.now(),
            imageUrl: _imageUrl,
          );
          
          await context.read<DatabaseService>().addCoffee(newCoffee);
        } else {
          final updatedCoffee = widget.coffee!.copyWith(
            name: _nameController.text,
            roaster: _roasterController.text,
            origin: _originController.text,
            flavorProfile: _flavorProfileController.text,
            roastDate: _roastDate,
            imageUrl: _imageUrl,
          );
          
          await context.read<DatabaseService>().updateCoffee(updatedCoffee);
        }
        
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving coffee: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.coffee == null ? 'Add Coffee' : 'Edit Coffee'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                            image: _imageUrl != null
                            ? DecorationImage(
                                image: _imageUrl!.startsWith('http')
                                    ? NetworkImage(_imageUrl!)
                                    : FileImage(File(_imageUrl!)) as ImageProvider,
                                fit: BoxFit.cover,
                              )
                            : null,
                          ),
                          child: _imageFile == null && _imageUrl == null
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_photo_alternate_outlined,
                                        size: 50,
                                        color: Colors.grey.shade700,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Add Coffee Photo',
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Coffee Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a coffee name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _roasterController,
                        decoration: const InputDecoration(
                          labelText: 'Roaster',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _originController,
                        decoration: const InputDecoration(
                          labelText: 'Origin / Country',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _flavorProfileController,
                        decoration: const InputDecoration(
                          labelText: 'Flavor Profile',
                          border: OutlineInputBorder(),
                          hintText: 'e.g., Citrus, Floral, Chocolate',
                        ),
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: _selectRoastDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Roast Date',
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _roastDate == null
                                    ? 'Select Date'
                                    : DateFormat.yMMMd().format(_roastDate!),
                                style: _roastDate == null
                                    ? TextStyle(color: Colors.grey.shade600)
                                    : null,
                              ),
                              const Icon(Icons.calendar_today),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
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
                              onPressed: _saveCoffee,
                              child: const Text('Save'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}