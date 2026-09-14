<?php

use App\Http\Controllers\Api\AbonnementController;
use App\Http\Controllers\Api\AgriculteurCommandeController;
use App\Http\Controllers\Api\AgriculteurProduitController;
use App\Http\Controllers\Api\AgriculteurStatsController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CommandeController;
use App\Http\Controllers\Api\LivraisonController;
use App\Http\Controllers\Api\MessageController;
use App\Http\Controllers\Api\NotationController;
use App\Http\Controllers\Api\PaiementController;
use App\Http\Controllers\Api\PaiementWebhookController;
use App\Http\Controllers\Api\PositionController;
use App\Http\Controllers\Api\ProduitController;
use Illuminate\Support\Facades\Route;

// ============================================================
// Routes API pour Flutter (préfixe /api/ automatique)
// ============================================================

// --- Routes publiques ---
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

Route::get('/produits', [ProduitController::class, 'index']);
Route::get('/produits/{produit}', [ProduitController::class, 'show']);

Route::get('/agriculteurs/{agriculteur}/notations', [NotationController::class, 'index']);

Route::post('/webhooks/notchpay', [PaiementWebhookController::class, 'handle']);

// --- Routes protégées ---
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/me', [AuthController::class, 'me']);

    Route::post('/paiements/{paiement}/payer', [PaiementController::class, 'payer']);

    // --- Acheteur uniquement ---
    Route::middleware('role.api:acheteur')->group(function () {
        Route::get('/commandes', [CommandeController::class, 'index']);
        Route::post('/commandes', [CommandeController::class, 'store']);
        Route::get('/commandes/{commande}', [CommandeController::class, 'show']);
        Route::patch('/commandes/{commande}', [CommandeController::class, 'update']);
        Route::delete('/commandes/{commande}', [CommandeController::class, 'destroy']);

        Route::post('/notations', [NotationController::class, 'store']);
    });

    // --- Agriculteur uniquement ---
    Route::middleware('role.api:agriculteur')->group(function () {
        Route::apiResource('mes-produits', AgriculteurProduitController::class)
            ->parameters(['mes-produits' => 'produit']);

        Route::get('/mes-commandes', [AgriculteurCommandeController::class, 'index']);
        Route::patch('/commandes/{commande}/notifier-transporteur', [AgriculteurCommandeController::class, 'notifierTransporteur']);

        Route::post('/abonnement/souscrire', [AbonnementController::class, 'souscrire']);
        Route::get('/abonnement/statut', [AbonnementController::class, 'statut']);

        Route::get('/simuler-revenus', [AgriculteurStatsController::class, 'simulerRevenus']);
        Route::get('/prediction-prix', [AgriculteurStatsController::class, 'predictionPrix']);
    });

    // --- Transporteur uniquement ---
    Route::middleware('role.api:transporteur')->group(function () {
        Route::get('/livraisons/disponibles', [LivraisonController::class, 'disponibles']);
        Route::get('/livraisons', [LivraisonController::class, 'index']);
        Route::patch('/livraisons/{livraison}/prendre-en-charge', [LivraisonController::class, 'prendreEnCharge']);
        Route::patch('/livraisons/{livraison}/statut', [LivraisonController::class, 'updateStatut']);
        Route::get('/livraisons/{livraison}/position-acheteur', [LivraisonController::class, 'positionAcheteur']);
    });

    // --- Acheteur ET Transporteur ---
    Route::middleware('role.api:acheteur,transporteur')->group(function () {
        Route::post('/position', [PositionController::class, 'update']);

        Route::get('/livraisons/{livraison}/messages', [MessageController::class, 'index']);
        Route::post('/livraisons/{livraison}/messages', [MessageController::class, 'store']);
    });
});
