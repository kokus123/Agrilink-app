<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Produit extends Model
{
    use HasFactory;

    protected $fillable = [
        'agriculteur_id',
        'nom',
        'description',
        'categorie',
        'prix',
        'quantite_disponible',
        'image',
        'unite',
        'statut',
    ];

    protected function casts(): array
    {
        return [
            'prix' => 'decimal:2',
        ];
    }

    public function agriculteur()
    {
        return $this->belongsTo(User::class, 'agriculteur_id');
    }

    public function commandes()
    {
        return $this->belongsToMany(Commande::class, 'commande_produit')
            ->withPivot('quantite', 'prix_unitaire')
            ->withTimestamps();
    }

    public function scopeDisponibles($query)
    {
        return $query->where('statut', 'disponible');
    }
}
