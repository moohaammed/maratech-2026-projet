import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import '../../../admin/models/user_model.dart';
/// Create event screen — for coach_admin / main_admin / group_admin only.
class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _timeController = TextEditingController(text: '09:00');
  final _distanceController = TextEditingController();

  EventType _eventType = EventType.daily;
  WeeklyEventSubType _weeklySubType = WeeklyEventSubType.longRun;
  RunningGroup? _selectedGroup = RunningGroup.group1;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  final EventService _eventService = EventService();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _timeController.dispose();
    _distanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Créer un événement', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titre *',
                  prefixIcon: Icon(Icons.title),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<EventType>(
                value: _eventType,
                decoration: const InputDecoration(
                  labelText: 'Type d\'événement *',
                  prefixIcon: Icon(Icons.event),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
                items: const [
                  DropdownMenuItem(value: EventType.daily, child: Text('Quotidien (par groupe)')),
                  DropdownMenuItem(value: EventType.weekly, child: Text('Hebdomadaire')),
                ],
                onChanged: (value) => setState(() {
                  _eventType = value ?? EventType.daily;
                  if (_eventType == EventType.weekly) {
                    _selectedGroup = null;
                  } else {
                    _selectedGroup = RunningGroup.group1;
                  }
                }),
              ),
              if (_eventType == EventType.weekly) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<WeeklyEventSubType>(
                  value: _weeklySubType,
                  decoration: const InputDecoration(
                    labelText: 'Sous-type *',
                    prefixIcon: Icon(Icons.directions_run),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                  items: const [
                    DropdownMenuItem(value: WeeklyEventSubType.longRun, child: Text('Sortie longue')),
                    DropdownMenuItem(value: WeeklyEventSubType.specialEvent, child: Text('Course officielle')),
                  ],
                  onChanged: (value) => setState(() => _weeklySubType = value ?? WeeklyEventSubType.longRun),
                ),
              ],
              if (_eventType == EventType.daily) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<RunningGroup>(
                  value: _selectedGroup,
                  decoration: const InputDecoration(
                    labelText: 'Groupe *',
                    prefixIcon: Icon(Icons.group),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                  items: RunningGroup.values.map((g) {
                    return DropdownMenuItem(
                      value: g,
                      child: Text(_groupLabel(g)),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedGroup = value),
                ),
              ],
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date *'),
                subtitle: Text(
                  '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _timeController,
                decoration: const InputDecoration(
                  labelText: 'Heure *',
                  hintText: '09:00',
                  prefixIcon: Icon(Icons.access_time),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Lieu *',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _distanceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Distance (km)',
                  prefixIcon: Icon(Icons.straighten),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Créer l\'événement', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _groupLabel(RunningGroup g) {
    switch (g) {
      case RunningGroup.group1: return 'Groupe 1';
      case RunningGroup.group2: return 'Groupe 2';
      case RunningGroup.group3: return 'Groupe 3';
      case RunningGroup.group4: return 'Groupe 4';
      case RunningGroup.group5: return 'Groupe 5';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_eventType == EventType.daily && _selectedGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un groupe pour un événement quotidien.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    double? distanceKm;
    final distStr = _distanceController.text.trim();
    if (distStr.isNotEmpty) {
      distanceKm = double.tryParse(distStr.replaceAll(',', '.'));
    }

    final event = EventModel(
      id: '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      type: _eventType,
      weeklySubType: _eventType == EventType.weekly ? _weeklySubType : null,
      group: _selectedGroup,
      date: DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day),
      time: _timeController.text.trim().isEmpty ? '09:00' : _timeController.text.trim(),
      location: _locationController.text.trim(),
      distanceKm: distanceKm,
      createdAt: DateTime.now(),
      createdBy: FirebaseAuth.instance.currentUser?.uid,
    );

    try {
      await _eventService.createEvent(event);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Événement créé.'), backgroundColor: AppColors.success),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
