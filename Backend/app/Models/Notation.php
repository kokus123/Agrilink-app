<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Notation extends Model
{
    use HasFactory;

    protected $fillable = [
        'acheteur_id',
        'agriculteur_id',
        'commande_id',
        'note',
        'commentaire',
    ];

    public function acheteur()
    {
        return $this->belongsTo(User::class, 'acheteur_id');
    }

    public function agriculteur()
    {
        return $this->belongsTo(User::class, 'agriculteur_id');
    }

    public function commande()
    {
        return $this->belongsTo(Commande::class);
    }
}
