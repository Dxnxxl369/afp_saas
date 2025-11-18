// lib/screens/presupuesto/periodo_form.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/periodo_presupuestario.dart';
import '../../providers/presupuesto_provider.dart';

class PeriodoForm extends StatefulWidget {
  final PeriodoPresupuestario? periodo;

  const PeriodoForm({super.key, this.periodo});

  @override
  State<PeriodoForm> createState() => _PeriodoFormState();
}

class _PeriodoFormState extends State<PeriodoForm> {
  final _formKey = GlobalKey<FormState>();
  late String _nombre;
  late DateTime _fechaInicio;
  late DateTime _fechaFin;
  late String _estado;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.periodo != null) {
      _nombre = widget.periodo!.nombre;
      _fechaInicio = widget.periodo!.fechaInicio;
      _fechaFin = widget.periodo!.fechaFin;
      _estado = widget.periodo!.estado;
    } else {
      _nombre = '';
      _fechaInicio = DateTime.now();
      _fechaFin = DateTime.now().add(const Duration(days: 365));
      _estado = 'PLANIFICACION';
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _fechaInicio : _fechaFin,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != (isStartDate ? _fechaInicio : _fechaFin)) {
      setState(() {
        if (isStartDate) {
          _fechaInicio = picked;
        } else {
          _fechaFin = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    final provider = context.read<PresupuestoProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final periodoData = {
        'nombre': _nombre,
        'fecha_inicio': DateFormat('yyyy-MM-dd').format(_fechaInicio),
        'fecha_fin': DateFormat('yyyy-MM-dd').format(_fechaFin),
        'estado': _estado,
      };

      if (widget.periodo == null) {
        await provider.addPeriodo(periodoData);
      } else {
        await provider.updatePeriodo(widget.periodo!.id, periodoData);
      }
      Navigator.of(context).pop(); // Cierra el formulario
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error al guardar: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.periodo == null ? 'Nuevo Período' : 'Editar Período',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              TextFormField(
                initialValue: _nombre,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) => (value == null || value.isEmpty) ? 'Campo requerido' : null,
                onSaved: (value) => _nombre = value!,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, true),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Fecha Inicio'),
                        child: Text(DateFormat('yyyy-MM-dd').format(_fechaInicio)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, false),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Fecha Fin'),
                        child: Text(DateFormat('yyyy-MM-dd').format(_fechaFin)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _estado,
                decoration: const InputDecoration(labelText: 'Estado'),
                items: ['PLANIFICACION', 'ACTIVO', 'CERRADO']
                    .map((label) => DropdownMenuItem(
                          value: label,
                          child: Text(label),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _estado = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('Guardar'),
                    ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
