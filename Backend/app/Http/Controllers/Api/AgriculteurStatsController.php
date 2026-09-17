<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Produit;
use App\Services\GeminiService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class AgriculteurStatsController extends Controller
{
    /**
     * GET /api/simuler-revenus
     *
     * Envoie le stock réel de l'agriculteur (nom, catégorie, prix, quantité
     * disponible) à Gemini, qui estime le revenu potentiel et un revenu
     * réaliste, avec une explication en français destinée à un agriculteur
     * non technique.
     */
    public function simulerRevenus(Request $request)
    {
        $produits = $request->user()
            ->produits()
            ->where('statut', 'disponible')
            ->get(['nom', 'categorie', 'prix', 'quantite_disponible']);

        if ($produits->isEmpty()) {
            return response()->json([
                'revenu_potentiel_stock_actuel' => 0,
                'revenu_reel_estime' => 0,
                'nombre_produits_actifs' => 0,
                'explication' => "Aucun produit disponible pour l'instant — ajoute des produits à ton catalogue pour voir une simulation.",
            ]);
        }

        $stockJson = $produits->map(fn ($p) => [
            'nom' => $p->nom,
            'categorie' => $p->categorie,
            'prix_fcfa' => (float) $p->prix,
            'quantite_disponible' => (float) $p->quantite_disponible,
        ])->toJson(JSON_UNESCAPED_UNICODE);

        $prompt = <<<PROMPT
Tu es un assistant spécialisé dans l'agriculture et le commerce de produits vivriers au Cameroun.

Un agriculteur vend ses produits sur AgriLink, une plateforme de mise en relation directe entre agriculteurs et acheteurs. Voici son stock actuel disponible à la vente :

{$stockJson}

En te basant sur les prix affichés et sur ta connaissance des prix courants du marché camerounais pour ce type de produits, estime :
1. revenu_potentiel_stock_actuel : le revenu total si absolument tout le stock listé est vendu au prix affiché
2. revenu_reel_estime : un revenu réaliste probable, en tenant compte du marché, de la saisonnalité et du risque d'invendus
3. explication : 2 à 3 phrases en français, simples et concrètes, destinées à un agriculteur non technique, expliquant ton estimation

Réponds uniquement avec les champs demandés.
PROMPT;

        $schema = [
            'type' => 'OBJECT',
            'properties' => [
                'revenu_potentiel_stock_actuel' => ['type' => 'NUMBER'],
                'revenu_reel_estime' => ['type' => 'NUMBER'],
                'explication' => ['type' => 'STRING'],
            ],
            'required' => ['revenu_potentiel_stock_actuel', 'revenu_reel_estime', 'explication'],
        ];

        try {
            $gemini = new GeminiService(config('services.gemini.api_key'));
            $resultat = $gemini->genererJson($prompt, $schema);

            return response()->json([
                'revenu_potentiel_stock_actuel' => $resultat['revenu_potentiel_stock_actuel'],
                'revenu_reel_estime' => $resultat['revenu_reel_estime'],
                'nombre_produits_actifs' => $produits->count(),
                'explication' => $resultat['explication'],
            ]);
        } catch (\Throwable $e) {
            Log::error('Gemini simulerRevenus a échoué', ['error' => $e->getMessage()]);

            return response()->json([
                'message' => "L'assistant IA n'a pas pu générer d'estimation pour le moment. Réessaie dans un instant.",
            ], 503);
        }
    }

    /**
     * GET /api/prediction-prix?categorie=...
     *
     * Envoie à Gemini les prix actuellement pratiqués par TOUS les
     * agriculteurs de la plateforme pour cette catégorie (prix de marché,
     * pas seulement ceux de l'agriculteur connecté), et demande une
     * prédiction pour la semaine à venir.
     */
    public function predictionPrix(Request $request)
    {
        $validated = $request->validate([
            'categorie' => ['required', 'string', 'max:100'],
        ]);

        $categorie = $validated['categorie'];

        $prix = Produit::where('categorie', $categorie)
            ->where('statut', 'disponible')
            ->pluck('prix');

        if ($prix->isEmpty()) {
            return response()->json([
                'categorie' => $categorie,
                'prix_moyen_marche' => 0,
                'prix_min' => 0,
                'prix_max' => 0,
                'tendance' => 'inconnue',
                'echantillon' => 0,
                'note' => "Aucun produit de cette catégorie n'est actuellement en vente sur la plateforme — pas assez de données pour une prédiction.",
            ]);
        }

        $prixJson = $prix->map(fn ($p) => (float) $p)->toJson();

        $prompt = <<<PROMPT
Tu es un assistant spécialisé dans les prix des produits agricoles au Cameroun.

Sur AgriLink (plateforme camerounaise de vente directe producteur-acheteur), voici les prix actuellement pratiqués (en FCFA) par les agriculteurs pour la catégorie "{$categorie}" :

{$prixJson}

En te basant sur ces prix et sur les tendances saisonnières typiques du marché camerounais pour ce type de produits, prédis pour la semaine à venir :
1. prix_moyen_marche : le prix moyen probable
2. prix_min et prix_max : la fourchette attendue
3. tendance : "hausse", "stable" ou "baisse"
4. note : 2 à 3 phrases en français expliquant simplement cette prédiction à un agriculteur

Réponds uniquement avec les champs demandés.
PROMPT;

        $schema = [
            'type' => 'OBJECT',
            'properties' => [
                'prix_moyen_marche' => ['type' => 'NUMBER'],
                'prix_min' => ['type' => 'NUMBER'],
                'prix_max' => ['type' => 'NUMBER'],
                'tendance' => ['type' => 'STRING'],
                'note' => ['type' => 'STRING'],
            ],
            'required' => ['prix_moyen_marche', 'prix_min', 'prix_max', 'tendance', 'note'],
        ];

        try {
            $gemini = new GeminiService(config('services.gemini.api_key'));
            $resultat = $gemini->genererJson($prompt, $schema);

            return response()->json([
                'categorie' => $categorie,
                'prix_moyen_marche' => $resultat['prix_moyen_marche'],
                'prix_min' => $resultat['prix_min'],
                'prix_max' => $resultat['prix_max'],
                'tendance' => $resultat['tendance'],
                'echantillon' => $prix->count(),
                'note' => $resultat['note'],
            ]);
        } catch (\Throwable $e) {
            Log::error('Gemini predictionPrix a échoué', ['error' => $e->getMessage()]);

            return response()->json([
                'message' => "L'assistant IA n'a pas pu générer de prédiction pour le moment. Réessaie dans un instant.",
            ], 503);
        }
    }
}
