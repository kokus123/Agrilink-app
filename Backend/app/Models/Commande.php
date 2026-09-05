<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Commande extends Model
{
    use HasFactory;

    protected $fillable = [
        'acheteur_id',
        'montant_total',
        'statut',
    ];

    protected function casts(): array
    {
        return [
            'montant_total' => 'decimal:2',
        ];
    }

    public function acheteur()
    {
        return $this->belongsTo(User::class, 'acheteur_id');
    }

    public function produits()
    {
        return $this->belongsToMany(Produit::class, 'commande_produit')
            ->withPivot('quantite', 'prix_unitaire')
            ->withTimestamps();
    }

    public function livraison()
    {
        return $this->hasOne(Livraison::class);
    }

    public function paiement()
    {
        return $this->hasOne(Paiement::class);
    }

    public function scopeStatut($query, string $statut)
    {
        return $query->where('statut', $statut);
    }
}
