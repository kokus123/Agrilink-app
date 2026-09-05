<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'name',
        'email',
        'phone',
        'password',
        'role',
        'is_active',
        'is_subscribed',
        'subscription_expires_at',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'is_active' => 'boolean',
            'is_subscribed' => 'boolean',
            'subscription_expires_at' => 'datetime',
        ];
    }

    // ---------- Relations ----------

    /** Produits publiés (si role = agriculteur) */
    public function produits()
    {
        return $this->hasMany(Produit::class, 'agriculteur_id');
    }

    /** Commandes passées (si role = acheteur) */
    public function commandes()
    {
        return $this->hasMany(Commande::class, 'acheteur_id');
    }

    /** Livraisons assignées (si role = transporteur) */
    public function livraisons()
    {
        return $this->hasMany(Livraison::class, 'transporteur_id');
    }

    /** Paiements effectués */
    public function paiements()
    {
        return $this->hasMany(Paiement::class);
    }

    /** Notations reçues (si role = agriculteur) */
    public function notationsRecues()
    {
        return $this->hasMany(Notation::class, 'agriculteur_id');
    }

    /** Notations données (si role = acheteur) */
    public function notationsDonnees()
    {
        return $this->hasMany(Notation::class, 'acheteur_id');
    }

    // ---------- Scopes utiles pour le dashboard admin ----------

    public function scopeRole($query, string $role)
    {
        return $query->where('role', $role);
    }

    public function scopeActifs($query)
    {
        return $query->where('is_active', true);
    }

    public function scopeBloques($query)
    {
        return $query->where('is_active', false);
    }

    public function scopeAbonnesPremium($query)
    {
        return $query->where('is_subscribed', true)
            ->where(function ($q) {
                $q->whereNull('subscription_expires_at')
                  ->orWhere('subscription_expires_at', '>', now());
            });
    }

    // ---------- Accessors ----------

    public function getMoyenneNoteAttribute(): ?float
    {
        return round($this->notationsRecues()->avg('note') ?? 0, 1);
    }
}