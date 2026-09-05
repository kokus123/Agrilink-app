<?php

use Illuminate\Support\Facades\Route;

// Route "home" : requise par la vue de login (logo cliquable).
// Redirige simplement vers la page de connexion pour l'instant.
Route::redirect('/', '/login')->name('home');

// ============================================================
// Routes Admin (AGRILINK)
// ============================================================
Route::middleware(['auth', 'role:admin'])
    ->prefix('admin')
    ->name('admin.')
    ->group(function () {

        Route::livewire('/', 'admin.dashboard')->name('dashboard');
        Route::livewire('/utilisateurs', 'admin.utilisateurs')->name('utilisateurs');
        Route::livewire('/abonnements', 'admin.abonnements')->name('abonnements');
        Route::livewire('/statistiques', 'admin.statistiques')->name('statistiques');
    });