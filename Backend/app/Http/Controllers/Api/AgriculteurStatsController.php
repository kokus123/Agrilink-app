<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Produit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AgriculteurStatsController extends Controller
{
    /**
     * GET /api/simuler-revenus
     * Estimation basée sur le stock actuel valorisé au prix de vente.
     * (Calcul simple pour l'instant — pourra être remplacé par un vrai modèle
     * prenant l'historique de vente, une fois l'Assistant IA branché — voir Phase 4.)
     */
    public function simulerRevenus(Request $request)
    {
        $produits = $request->user()->produits()->where('statut', 'disponible')->get();

        $revenuPotentiel = $produits->sum(fn ($p) => $p->prix * $p->quantite_disponible);

        // Revenus réels des 3 derniers mois, pour comparaison
        $revenuReel3Mois = DB::table('commande_produit')
            ->join('produits', 'commande_produit.produit_id', '=', 'produits.id')
            ->join('commandes', 'commande_produit.commande_id', '=', 'commandes.id')
            ->where('produits.agriculteur_id', $request->user()->id)
            ->where('commandes.statut', 'livree')
            ->where('commandes.created_at', '>=', now()->subMonths(3))
            ->sum(DB::raw('commande_produit.quantite * commande_produit.prix_unitaire'));

        return response()->json([
            'revenu_potentiel_stock_actuel' => (float) $revenuPotentiel,
            'revenu_reel_3_derniers_mois' => (float) $revenuReel3Mois,
            'nombre_produits_actifs' => $produits->count(),
        ]);
    }

    /**
     * GET /api/prediction-prix?categorie=Légumes
     * Version simple : moyenne des prix du marché sur la catégorie.
     * À remplacer par l'appel réel à l'Assistant IA externe (Phase 4).
     */
    public function predictionPrix(Request $request)
    {
        $request->validate([
            'categorie' => ['required', 'string'],
        ]);

        $stats = Produit::where('categorie', $request->categorie)
            ->where('statut', 'disponible')
            ->selectRaw('AVG(prix) as prix_moyen, MIN(prix) as prix_min, MAX(prix) as prix_max, COUNT(*) as nb_produits')
            ->first();

        return response()->json([
            'categorie' => $request->categorie,
            'prix_moyen_marche' => round((float) $stats->prix_moyen, 2),
            'prix_min' => (float) $stats->prix_min,
            'prix_max' => (float) $stats->prix_max,
            'echantillon' => (int) $stats->nb_produits,
            'note' => "Estimation basée sur les prix actuels du marché. Un modèle IA plus avancé sera branché ultérieurement.",
        ]);
    }
}
