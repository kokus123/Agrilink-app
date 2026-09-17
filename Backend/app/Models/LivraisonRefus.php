<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class LivraisonRefus extends Model
{
    /**
     * Nom de table forcé explicitement — la pluralisation automatique de
     * Laravel (règles anglaises) transformait "livraison_refus" en
     * "livraison_refuses" (comme "bus" -> "buses"), qui ne correspond pas
     * au nom réel créé par la migration.
     */
    protected $table = 'livraison_refus';

    public $timestamps = false; // on n'a que created_at, géré par la BDD (useCurrent)

    protected $fillable = [
        'livraison_id',
        'transporteur_id',
        'created_at',
    ];

    public function livraison()
    {
        return $this->belongsTo(Livraison::class);
    }

    public function transporteur()
    {
        return $this->belongsTo(User::class, 'transporteur_id');
    }
}
