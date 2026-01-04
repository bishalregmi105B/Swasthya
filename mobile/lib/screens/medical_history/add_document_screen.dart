import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:swasthya/l10n/generated/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../services/live_ai_call_service.dart';
import '../../widgets/ai/live_ai_call_widget.dart';

class AddDocumentScreen extends StatefulWidget {
  const AddDocumentScreen({super.key});

  @override
  State<AddDocumentScreen> createState() => _AddDocumentScreenState();
}

class _AddDocumentScreenState extends State<AddDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _doctorController = TextEditingController();
  final _hospitalController = TextEditingController();

  String _documentType = 'lab_report';
  DateTime _documentDate = DateTime.now();
  bool _isCritical = false;
  bool _isSubmitting = false;
  List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  final List<Map<String, String>> _documentTypes = [
    {'value': 'lab_report', 'label': 'Lab Report'},
    {'value': 'prescription', 'label': 'Prescription'},
    {'value': 'blood_test', 'label': 'Blood Test'},
    {'value': 'xray', 'label': 'X-Ray'},
    {'value': 'mri', 'label': 'MRI Scan'},
    {'value': 'ct_scan', 'label': 'CT Scan'},
    {'value': 'ultrasound', 'label': 'Ultrasound'},
    {'value': 'ecg', 'label': 'ECG/EKG'},
    {'value': 'discharge_summary', 'label': 'Discharge Summary'},
    {'value': 'vaccination', 'label': 'Vaccination Record'},
    {'value': 'pathology', 'label': 'Pathology Report'},
    {'value': 'referral', 'label': 'Referral Letter'},
    {'value': 'insurance', 'label': 'Insurance Document'},
    {'value': 'other', 'label': 'Other'},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _doctorController.dispose();
    _hospitalController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking images: $e')),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        setState(() {
          _selectedImages.add(photo);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking photo: $e')),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _documentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _documentDate = picked);
    }
  }

  Future<void> _submitDocument() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // Prepare document data
      final docData = <String, dynamic>{
        'title': _titleController.text,
        'document_type': _documentType,
        'description': _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        'document_date': _documentDate.toIso8601String().split('T')[0],
        'doctor_name':
            _doctorController.text.isEmpty ? null : _doctorController.text,
        'hospital_name':
            _hospitalController.text.isEmpty ? null : _hospitalController.text,
        'is_critical': _isCritical,
      };

      // If there's an image, encode it as base64 for AI analysis
      if (_selectedImages.isNotEmpty) {
        final firstImage = _selectedImages.first;
        final imageBytes = await firstImage.readAsBytes();
        final base64Image = base64Encode(imageBytes);
        docData['image_data'] = base64Image;
        docData['filename'] = firstImage.name;
      }

      final result = await apiService.addMedicalDocument(docData);

      // Add additional images if there are more than one
      if (_selectedImages.length > 1 && result['document'] != null) {
        final docId = result['document']['id'];
        for (int i = 1; i < _selectedImages.length; i++) {
          await apiService.addDocumentImage(docId, {
            'image_url': 'local://${_selectedImages[i].path}',
            'page_number': i + 1,
          });
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _openAIHelp() {
    showLiveAICallBottomSheet(
      context: context,
      config: LiveAICallConfig(
        specialist: 'physician',
        patientContext:
            'User is uploading a medical document:\nType: ${_documentTypes.firstWhere((t) => t['value'] == _documentType)['label']}\nTitle: ${_titleController.text}\n\nHelp them understand what information to include and answer any questions about this type of document.',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.addMedicalDocument),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'AI Help',
            onPressed: _openAIHelp,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Document Type
              DropdownButtonFormField<String>(
                value: _documentType,
                decoration: const InputDecoration(
                  labelText: 'Document Type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.folder),
                ),
                items: _documentTypes
                    .map((type) => DropdownMenuItem(
                          value: type['value'],
                          child: Text(type['label']!),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _documentType = value);
                },
              ),
              const SizedBox(height: 16),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Document Title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                  hintText: 'e.g., Blood Test Report - Jan 2026',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date Picker
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Document Date',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    '${_documentDate.day}/${_documentDate.month}/${_documentDate.year}',
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                  hintText: 'Brief description or notes...',
                ),
              ),
              const SizedBox(height: 16),

              // Doctor Name
              TextFormField(
                controller: _doctorController,
                decoration: const InputDecoration(
                  labelText: 'Doctor Name (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),

              // Hospital Name
              TextFormField(
                controller: _hospitalController,
                decoration: const InputDecoration(
                  labelText: 'Hospital/Clinic Name (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.local_hospital),
                ),
              ),
              const SizedBox(height: 16),

              // Critical Flag
              SwitchListTile(
                title: Text(AppLocalizations.of(context)!.markAsCritical),
                subtitle:
                    Text(AppLocalizations.of(context)!.flagAbnormalResults),
                value: _isCritical,
                onChanged: (value) => setState(() => _isCritical = value),
                activeColor: Colors.red,
              ),
              const SizedBox(height: 24),

              // Image Section
              Text('Attach Images',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                'Take photos or select images of your medical report',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(height: 12),

              // Image Picker Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _takePhoto,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Camera'),
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(16)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickImages,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Gallery'),
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(16)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Selected Images Preview
              if (_selectedImages.isNotEmpty) ...[
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) {
                      return Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[200],
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: FutureBuilder(
                                future: _selectedImages[index].readAsBytes(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    return Image.memory(
                                      snapshot.data!,
                                      fit: BoxFit.cover,
                                    );
                                  }
                                  return const Center(
                                      child: CircularProgressIndicator());
                                },
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removeImage(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close,
                                      color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // AI Analysis Note
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('AI Analysis',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700])),
                          const Text(
                            'Your document will be automatically analyzed by AI to extract key information.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitDocument,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Save Document',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
