import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/notation_recue_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/notation_consultation_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/error_banner.dart';

class MesNotationsScreen extends StatefulWidget {
  const MesNotationsScreen({super.key});

  @override
  State<MesNotationsScreen> createState() => _MesNotationsScreenState();
}

class _MesNotationsScreenState extends State<MesNotationsScreen> {
  final NotationConsultationService _service = NotationConsultationService();
  List<NotationRecue> _notations = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _charger());
  }

  Future<void> _charger() async {
    final monId = context.read<AuthProvider>().user?.id;
    if (monId == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final notations = await _service.getNotationsDe(monId);
      if (mounted) setState(() => _notations = notations);
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorMessage = e.userFriendlyMessage);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Erreur inattendue : $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double get _moyenne {
    if (_notations.isEmpty) return 0;
    return _notations.map((n) => n.note).reduce((a, b) => a + b) / _notations.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Mes notations')),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _charger,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  if (_errorMessage != null) ErrorBanner(message: _errorMessage!),
                  if (_notations.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: AppColors.brandGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _moyenne.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: List.generate(5, (i) {
                                    final rempli = i < _moyenne.round();
                                    return Icon(
                                      rempli ? Icons.star_rounded : Icons.star_border_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    );
                                  }),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_notations.length} avis',
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (_notations.isEmpty && !_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                        child: Text(
                          "Aucun avis pour l'instant.",
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  for (final notation in _notations)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.inputBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Row(
                                children: List.generate(
                                  5,
                                  (i) => Icon(
                                    i < notation.note ? Icons.star_rounded : Icons.star_border_rounded,
                                    color: AppColors.warning,
                                    size: 16,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                notation.acheteurNom ?? 'Acheteur',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          if (notation.commentaire != null && notation.commentaire!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(notation.commentaire!, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
