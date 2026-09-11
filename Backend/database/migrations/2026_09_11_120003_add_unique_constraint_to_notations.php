<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('notations', function (Blueprint $table) {
            // One rating per (acheteur, agriculteur, commande) - blocks duplicate reviews.
            // A commande can hold products from several agriculteurs (multi-vendor cart),
            // so agriculteur_id is part of the key, not just commande_id.
            $table->unique(['acheteur_id', 'agriculteur_id', 'commande_id'], 'notations_unique_par_commande');
        });
    }

    public function down(): void
    {
        Schema::table('notations', function (Blueprint $table) {
            $table->dropUnique('notations_unique_par_commande');
        });
    }
};
