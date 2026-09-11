<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\UpdatePositionRequest;
use Illuminate\Support\Facades\DB;

class PositionController extends Controller
{
    /**
     * POST /api/position
     * Partager sa position actuelle (Acheteur ou Transporteur)
     */
    public function update(UpdatePositionRequest $request)
    {
        $request->user()->update([
            'latitude' => $request->latitude,
            'longitude' => $request->longitude,
            'position_updated_at' => now(),
        ]);

        // Si c'est un transporteur en cours de livraison, on met aussi à jour
        // la position sur la livraison active pour un historique plus précis.
        if ($request->user()->role === 'transporteur') {
            DB::table('livraisons')
                ->where('transporteur_id', $request->user()->id)
                ->where('statut', 'en_cours')
                ->update([
                    'latitude_actuelle' => $request->latitude,
                    'longitude_actuelle' => $request->longitude,
                    'updated_at' => now(),
                ]);
        }

        return response()->json(['message' => 'Position mise à jour.']);
    }
}
