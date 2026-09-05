<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('email')->unique();
            $table->string('phone')->nullable();
            $table->string('password');
            
            // Rôles alignés sur le diagramme
            $table->enum('role', ['admin', 'agriculteur', 'acheteur', 'transporteur'])
                  ->default('acheteur');

            // Modération des comptes (Actif / Bloqué)
            $table->boolean('is_active')->default(true);

            // Gestion de l'abonnement Premium (Agriculteurs)
            $table->boolean('is_subscribed')->default(false);
            $table->timestamp('subscription_expires_at')->nullable();

            $table->rememberToken();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('users');
    }
};