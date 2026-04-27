import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/instancia_service.dart';
import '../../core/theme/app_theme.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final _controller = TextEditingController();
  final _service = InstanciaService();
  bool _loading = false;
  String? _error;

  Future<void> _buscar() async {
    final id = _controller.text.trim();
    if (id.isEmpty) return;
    setState(() { _loading = true; _error = null; });
    try {
      final instancia = await _service.trackPublico(id);
      if (!mounted) return;
      context.push('/tracking/$id', extra: instancia);
    } catch (e) {
      setState(() { _error = 'No se encontró ningún proceso con ese ID.'; });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 64),
                  // Logo / Header
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.account_tree_outlined, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Orquestia',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  const Text(
                    'Rastrear proceso',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ingresa el ID de tu proceso para ver su progreso.',
                    style: TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.5),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'ID del proceso',
                      prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                      errorText: _error,
                    ),
                    onSubmitted: (_) => _buscar(),
                    textInputAction: TextInputAction.search,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loading ? null : _buscar,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Rastrear mi proceso'),
                  ),
                  const Spacer(),
                  Center(
                    child: TextButton(
                      onPressed: () => context.push('/login'),
                      child: const Text(
                        'Iniciar sesión como admin o funcionario →',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
