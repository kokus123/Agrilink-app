<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Laravel ne gère pas bien la modification d'un enum existant via le
     * Schema Builder (limitation Doctrine DBAL) — on passe par du SQL brut,
     * ce qui est sûr ici car le projet cible MySQL.
     */
    public function up(): void
    {
        DB::statement("ALTER TABLE livraisons MODIFY COLUMN statut ENUM('en_attente', 'proposee', 'en_cours', 'livree', 'annulee') DEFAULT 'en_attente'");
    }

    public function down(): void
    {
        DB::statement("ALTER TABLE livraisons MODIFY COLUMN statut ENUM('en_attente', 'en_cours', 'livree', 'annulee') DEFAULT 'en_attente'");
    }
};
