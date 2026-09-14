import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/produit_model.dart';
import '../../providers/produit_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/modern_button.dart';
import '../../widgets/modern_text_field.dart';

class ProduitFormScreen extends StatefulWidget {
  final ProduitModel? produit;

  const ProduitFormScreen({super.key, this.produit});

  bool get isEdition => produit != null;

  @override
  State<ProduitFormScreen> createState() => _ProduitFormScreenState();
}

class _ProduitFormScreenState extends State<ProduitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _categorieController;
  late final TextEditingController _prixController;
  late final TextEditingController _quantiteController;

  String _statut = 'disponible';
  bool _isSaving = false;
  String? _errorMessage;
  File? _imageSelectionnee;

  @override
  void initState() {
    super.initState();
    final p = widget.produit;
    _nomController = TextEditingController(text: p?.nom ?? '');
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _categorieController = TextEditingController(text: p?.categorie ?? '');
    _prixController = TextEditingController(text: p != null ? p.prix.toStringAsFixed(0) : '');
    _quantiteController = TextEditingController(text: p != null ? p.quantiteDisponible.toString() : '');
    _statut = p?.statut ?? 'disponible';
  }

  @override
  void dispose() {
    _nomController.dispose();
    _descriptionController.dispose();
    _categorieController.dispose();
    _prixController.dispose();
    _quantiteController.dispose();
    super.dispose();
  }

  Future<void> _choisirImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
              title: const Text('Choisir depuis la galerie'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: AppColors.primary),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1280,
      imageQuality: 85,
    );

    if (picked != null && mounted) {
      setState(() => _imageSelectionnee = File(picked.path));
    }
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final provider = context.read<ProduitProvider>();
    final nom = _nomController.text.trim();
    final description = _descriptionController.text.trim();
    final categorie = _categorieController.text.trim();
    final prix = double.tryParse(_prixController.text.trim().replaceAll(',', '.')) ?? 0;
    final quantite = int.tryParse(_quantiteController.text.trim()) ?? 0;

    final ok = widget.isEdition
        ? await provider.modifier(
            id: widget.produit!.id,
            nom: nom,
            description: description.isEmpty ? null : description,
            categorie: categorie.isEmpty ? null : categorie,
            prix: prix,
            quantiteDisponible: quantite,
            statut: _statut,
            image: _imageSelectionnee,
          )
        : await provider.creer(
            nom: nom,
            description: description.isEmpty ? null : description,
            categorie: categorie.isEmpty ? null : categorie,
            prix: prix,
            quantiteDisponible: quantite,
            image: _imageSelectionnee,
          );

    if (!mounted) return;

    setState(() => _isSaving = false);

    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() => _errorMessage = provider.errorMessage ?? "Échec de l'enregistrement.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasExistingImage = widget.produit?.image != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.isEdition ? 'Modifier le produit' : 'Nouveau produit'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null) ErrorBanner(message: _errorMessage!),

              // Sélecteur de photo
              GestureDetector(
                onTap: _choisirImage,
                child: Container(
                  height: 160,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: AppColors.inputBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.inputBorder, width: 1.2),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_imageSelectionnee != null)
                        Image.file(_imageSelectionnee!, fit: BoxFit.cover)
                      else if (hasExistingImage)
                        Image.network(widget.produit!.image!, fit: BoxFit.cover)
                      else
                        const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined, color: AppColors.textSecondary, size: 30),
                            SizedBox(height: 8),
                            Text(
                              'Ajouter une photo',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      if (_imageSelectionnee != null || hasExistingImage)
                        Positioned(
                          bottom: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                            child: const Icon(Icons.edit_outlined, color: Colors.white, size: 18),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              ModernTextField(
                controller: _nomController,
                label: 'Nom du produit',
                prefixIcon: Icons.inventory_2_outlined,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Le nom est requis.' : null,
              ),
              const SizedBox(height: 16),
              ModernTextField(
                controller: _categorieController,
                label: 'Catégorie',
                hintText: 'Ex : Légumes, Fruits, Céréales...',
                prefixIcon: Icons.category_outlined,
              ),
              const SizedBox(height: 16),
              ModernTextField(
                controller: _descriptionController,
                label: 'Description',
                prefixIcon: Icons.notes_outlined,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ModernTextField(
                      controller: _prixController,
                      label: 'Prix (FCFA)',
                      prefixIcon: Icons.sell_outlined,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final val = double.tryParse((v ?? '').replaceAll(',', '.'));
                        if (val == null || val < 0) return 'Prix invalide.';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ModernTextField(
                      controller: _quantiteController,
                      label: 'Quantité dispo.',
                      prefixIcon: Icons.numbers_rounded,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final val = int.tryParse(v ?? '');
                        if (val == null || val < 0) return 'Quantité invalide.';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              if (widget.isEdition) ...[
                const SizedBox(height: 16),
                const Text(
                  'Statut',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 7),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.inputBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.inputBorder, width: 1.2),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _statut,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'disponible', child: Text('Disponible')),
                        DropdownMenuItem(value: 'rupture', child: Text('Rupture de stock')),
                        DropdownMenuItem(value: 'archive', child: Text('Archivé')),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _statut = value);
                      },
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              ModernButton(
                text: widget.isEdition ? 'Enregistrer les modifications' : 'Créer le produit',
                icon: Icons.check_rounded,
                isLoading: _isSaving,
                onPressed: _enregistrer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
