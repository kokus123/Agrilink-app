<?php

namespace App\Http\Controllers\Api;

use App\Events\MessageEnvoye;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\StoreMessageRequest;
use App\Http\Resources\MessageResource;
use App\Models\Livraison;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class MessageController extends Controller
{
    /**
     * GET /api/livraisons/{livraison}/messages
     * Historique du chat pour cette livraison (remplace "Notifier transporteur" :
     * c'est ici que l'acheteur et le transporteur échangent pendant la livraison).
     */
    public function index(Request $request, Livraison $livraison): AnonymousResourceCollection
    {
        $this->authorize('chat', $livraison);

        $messages = $livraison->messages()
            ->with('expediteur:id,name,role')
            ->orderBy('created_at')
            ->get();

        // Marque comme lus les messages reçus (pas ceux que j'ai envoyés moi-même)
        $livraison->messages()
            ->where('expediteur_id', '!=', $request->user()->id)
            ->where('lu', false)
            ->update(['lu' => true]);

        return MessageResource::collection($messages);
    }

    /**
     * POST /api/livraisons/{livraison}/messages
     * Envoyer un message. Diffusé en temps réel sur le canal privé
     * "livraison.{id}" (voir routes/channels.php).
     */
    public function store(StoreMessageRequest $request, Livraison $livraison): MessageResource
    {
        $this->authorize('chat', $livraison);

        $message = $livraison->messages()->create([
            'expediteur_id' => $request->user()->id,
            'contenu' => $request->validated()['contenu'],
        ]);

        $message->load('expediteur:id,name,role');

        broadcast(new MessageEnvoye($message))->toOthers();

        return new MessageResource($message);
    }
}
