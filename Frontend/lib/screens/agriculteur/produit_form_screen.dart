import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/produit_model.dart';
import '../../providers/produit_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/modern_button.dart';
import '../../widgets/modern_text_field.dart';
import 'abonnement_screen.dart';

class ProduitFormScreen extends StatefulWidget {
  final ProduitModel? produit;

  const ProduitFormScreen({super.key, this.produit});

  bool get isEdition => produit != null;

  @override
  State<ProduitFormScreen> createState() => _ProduitFormScreenState();
}

class _ProduitFormScreenState extends State<ProduitFormScreen> {
  // Doit rester identique aux listes côté backend
  // (StoreProduitRequest::CATEGORIES / ::UNITES) — sinon le serveur
  // rejette une valeur que le formulaire pensait valide.
  static const List<String> _categories = [
    'Fruits', 'Légumes', 'Céréales', 'Tubercules', 'Légumineuses', 'Épices & Condiments', 'Autres',
  ];
  static const List<String> _unites = [
    'KG', 'Sac', 'Filet', 'Cageot', 'Tas', 'Botte', 'Caisse', 'Unité (pièce)',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _prixController;
  late final TextEditingController _quantiteController;

  String? _categorie;
  String? _unite;
  String _statut = 'disponible';
  bool _isSaving = false;
  String? _errorMessage;

  XFile? _imageSelectionnee;
  Uint8List? _imageBytesApercu;

  @override
  void initState() {
    super.initState();
    final p = widget.produit;
    _nomController = TextEditingController(text: p?.nom ?? '');
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _prixController = TextEditingController(text: p != null ? p.prix.toStringAsFixed(0) : '');
    _quantiteController = TextEditingController(text: p != null ? p.quantiteDisponible.toString() : '');
    // Ne pré-remplit que si la valeur existante correspond à une option
    // connue — un ancien produit avec une catégorie/unité en texte libre
    // (avant cette mise à jour) repart sur "non choisi" plutôt que planter.
    _categorie = (p?.categorie != null && _categories.contains(p!.categorie)) ? p.categorie : null;
    _unite = (p?.unite != null && _unites.contains(p!.unite)) ? p.unite : null;
    _statut = p?.statut ?? 'disponible';
  }

  @override
  void dispose() {
    _nomController.dispose();
    _descriptionController.dispose();
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
      final bytes = await picked.readAsBytes();
      if (mounted) {
        setState(() {
          _imageSelectionnee = picked;
          _imageBytesApercu = bytes;
        });
      }
    }
  }

  Future<void> _proposerPremium() async {
    final aClique = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.bolt_rounded, color: Color(0xFFFF8F00)),
            SizedBox(width: 8),
            Text('Limite atteinte', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Le forfait gratuit est limité à 2 produits publiés. Passe au premium pour publier sans limite.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Plus tard', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Passer premium'),
          ),
        ],
      ),
    );

    if (aClique == true && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AbonnementScreen()),
      );
    }
  }

  Future<void> _enregistrer() async {
    // Valide aussi les deux DropdownButtonFormField (ils ont leur propre
    // validator) — s'ils sont vides, validate() renvoie déjà false ici.
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final provider = context.read<ProduitProvider>();
    final nom = _nomController.text.trim();
    final description = _descriptionController.text.trim();
    final prix = int.tryParse(_prixController.text.trim()) ?? 0;
    final quantite = int.tryParse(_quantiteController.text.trim()) ?? 0;

    final ok = widget.isEdition
        ? await provider.modifier(
            id: widget.produit!.id,
            nom: nom,
            description: description.isEmpty ? null : description,
            categorie: _categorie,
            prix: prix.toDouble(),
            quantiteDisponible: quantite,
            unite: _unite!,
            statut: _statut,
            image: _imageSelectionnee,
          )
        : await provider.creer(
            nom: nom,
            description: description.isEmpty ? null : description,
            categorie: _categorie,
            prix: prix.toDouble(),
            quantiteDisponible: quantite,
            unite: _unite!,
            image: _imageSelectionnee,
          );

    if (!mounted) return;

    setState(() => _isSaving = false);

    if (ok) {
      Navigator.pop(context);
    } else if (provider.limitePremiumAtteinte) {
      _proposerPremium();
    } else {
      setState(() => _errorMessage = provider.errorMessage ?? "Échec de l'enregistrement.");
    }
  }

  InputDecoration _dropdownDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
      filled: true,
      fillColor: AppColors.inputBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.inputBorder, width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.inputBorder, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.error, width: 1.2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
    );
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
                      if (_imageBytesApercu != null)
                        Image.memory(_imageBytesApercu!, fit: BoxFit.cover)
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
                      if (_imageBytesApercu != null || hasExistingImage)
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

              // Catégorie — liste fermée (avant : texte libre), pour que le
              // filtre du catalogue reste cohérent (plus de "fruit" vs
              // "Fruits" vs "fruits").
              DropdownButtonFormField<String>(
                value: _categorie,
                decoration: _dropdownDecoration('Catégorie', Icons.category_outlined),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _categorie = v),
                validator: (v) => v == null ? 'Choisis une catégorie.' : null,
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
                        final texte = (v ?? '').trim();
                        // int.tryParse refuse tout ce qui n'est pas un
                        // entier pur ("2000.5", "2000,5", lettres...).
                        final val = int.tryParse(texte);
                        if (val == null || val < 0) return 'Nombre entier requis.';
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
              const SizedBox(height: 16),

              // Unité — se combine avec "Quantité dispo." ci-dessus pour
              // donner "50 KG", "2 Cageots", "1 Filet"...
              DropdownButtonFormField<String>(
                value: _unite,
                decoration: _dropdownDecoration('Unité (KG, Sac, Filet...)', Icons.scale_outlined),
                items: _unites.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                onChanged: (v) => setState(() => _unite = v),
                validator: (v) => v == null ? 'Choisis une unité.' : null,
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
