<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Livraison extends Model
{
    use HasFactory;

    protected $fillable = [
        'commande_id',
        'transporteur_id',
        'statut',
        'latitude_actuelle',
        'longitude_actuelle',
        'date_livraison_prevue',
        'date_livraison_reelle',
    ];

    protected function casts(): array
    {
        return [
            'date_livraison_prevue' => 'datetime',
            'date_livraison_reelle' => 'datetime',
        ];
    }

    public function commande()
    {
        return $this->belongsTo(Commande::class);
    }

    public function transporteur()
    {
        return $this->belongsTo(User::class, 'transporteur_id');
    }
}
