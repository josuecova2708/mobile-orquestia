import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_constants.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';

class InvitarAdminScreen extends StatefulWidget {
  const InvitarAdminScreen({super.key});

  @override
  State<InvitarAdminScreen> createState() => _InvitarAdminScreenState();
}

class _InvitarAdminScreenState extends State<InvitarAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final empresaId = context.read<AuthService>().user?.empresaId ?? '';
      await ApiClient().dio.post(
        ApiConstants.invitarAdmin,
        data: {
          'email': _emailCtrl.text.trim(),
          'nombre': _nombreCtrl.text.trim(),
          'apellido': _apellidoCtrl.text.trim(),
          'password': _passCtrl.text,
          'empresaId': empresaId,
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invitación enviada a ${_emailCtrl.text.trim()}'),
          backgroundColor: AppColors.completed,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al enviar la invitación. Verifica el email.'),
          backgroundColor: AppColors.cancelled,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invitar co-administrador')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Agregar co-admin',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'El nuevo administrador tendrá acceso a gestionar procesos en tu empresa.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requerido';
                  if (!v.contains('@')) return 'Email inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nombreCtrl,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                      validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _apellidoCtrl,
                      decoration: const InputDecoration(labelText: 'Apellido'),
                      validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passCtrl,
                decoration: InputDecoration(
                  labelText: 'Contraseña temporal',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                obscureText: _obscure,
                validator: (v) {
                  if (v == null || v.length < 6) return 'Mínimo 6 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _loading ? null : _enviar,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Enviar invitación'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
