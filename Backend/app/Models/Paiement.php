<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Paiement extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'type',
        'commande_id',
        'montant',
        'methode',
        'statut',
        'reference_api',
    ];

    protected function casts(): array
    {
        return [
            'montant' => 'decimal:2',
        ];
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function commande()
    {
        return $this->belongsTo(Commande::class);
    }

    public function scopeReussis($query)
    {
        return $query->where('statut', 'reussi');
    }

    public function scopeAbonnements($query)
    {
        return $query->where('type', 'abonnement');
    }

    public function scopeCommandes($query)
    {
        return $query->where('type', 'commande');
    }
}
