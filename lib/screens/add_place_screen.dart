import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../services/gemini_service.dart';

class AddPlaceScreen extends StatefulWidget {
  final GeminiService gemini;
  const AddPlaceScreen({Key? key, required this.gemini}) : super(key: key);

  @override
  State<AddPlaceScreen> createState() => _AddPlaceScreenState();
}

class _AddPlaceScreenState extends State<AddPlaceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final supa = SupabaseService.instance;
    final payload = {
      'name': _nameCtrl.text,
      'latitude': double.parse(_latCtrl.text),
      'longitude': double.parse(_lngCtrl.text),
      'category': _categoryCtrl.text,
      'image_url': _imageUrlCtrl.text,
      'creando_en': DateTime.now().toIso8601String(),
    };
    await supa.addPlace(payload);
    setState(() => _loading = false);
    Navigator.of(context).pop();
  }

  Future<void> _generateDescription() async {
    final prompt =
        'Genera una descripción breve y categorías para el lugar llamado: ${_nameCtrl.text}';
    final desc = await widget.gemini.generateDescription(prompt);
    // Aquí podríamos parsear categorías; por ahora colocamos en category
    _categoryCtrl.text = desc.split('\n').first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar lugar')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              TextFormField(
                controller: _latCtrl,
                decoration: const InputDecoration(labelText: 'Latitud'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              TextFormField(
                controller: _lngCtrl,
                decoration: const InputDecoration(labelText: 'Longitud'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              TextFormField(
                controller: _categoryCtrl,
                decoration: const InputDecoration(labelText: 'Categoría'),
              ),
              TextFormField(
                controller: _imageUrlCtrl,
                decoration: const InputDecoration(labelText: 'Image URL'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _generateDescription,
                child: const Text('Generar descripción y categoría (IA)'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
