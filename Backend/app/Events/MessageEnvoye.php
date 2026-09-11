<?php

namespace App\Events;

use App\Models\Message;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Queue\SerializesModels;

/**
 * Diffusé en temps réel à chaque message envoyé dans le chat d'une livraison.
 * ShouldBroadcastNow (et non ShouldBroadcast) : envoi synchrone, pas besoin
 * d'un worker de queue actif pour que le chat reste instantané.
 */
class MessageEnvoye implements ShouldBroadcastNow
{
    use InteractsWithSockets, SerializesModels;

    public function __construct(public Message $message)
    {
    }

    public function broadcastOn(): array
    {
        return [
            new PrivateChannel("livraison.{$this->message->livraison_id}"),
        ];
    }

    public function broadcastAs(): string
    {
        return 'message.envoye';
    }

    public function broadcastWith(): array
    {
        return [
            'id' => $this->message->id,
            'livraison_id' => $this->message->livraison_id,
            'expediteur_id' => $this->message->expediteur_id,
            'contenu' => $this->message->contenu,
            'created_at' => $this->message->created_at->toIso8601String(),
        ];
    }
}
