<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use RuntimeException;

/**
 * Thin wrapper around the Notch Pay REST API (https://developer.notchpay.co).
 *
 * Two-step flow:
 *  1. initialize()       — creates the payment on Notch Pay's side
 *  2. chargeMobileMoney() — triggers the USSD/app prompt on the customer's phone
 *
 * The actual confirmation always comes from the webhook (PaiementWebhookController),
 * never from the response of these two calls — Mobile Money confirmation is async.
 */
class NotchPayService
{
    private string $baseUrl = 'https://api.notchpay.co';

    public function __construct(private readonly string $publicKey)
    {
    }

    /**
     * POST /payments
     */
    public function initialize(array $data): array
    {
        $response = Http::withHeaders(['Authorization' => $this->publicKey])
            ->post("{$this->baseUrl}/payments", $data);

        if ($response->failed()) {
            throw new RuntimeException("NotchPay initialize failed: {$response->body()}");
        }

        return $response->json();
    }

    /**
     * POST /payments/{reference}
     * $channel: 'cm.mtn' or 'cm.orange' (Cameroon channel codes).
     */
    public function chargeMobileMoney(string $reference, string $channel, string $phone): array
    {
        $response = Http::withHeaders(['Authorization' => $this->publicKey])
            ->post("{$this->baseUrl}/payments/{$reference}", [
                'channel' => $channel,
                'data' => ['phone' => $phone],
            ]);

        if ($response->failed()) {
            throw new RuntimeException("NotchPay charge failed: {$response->body()}");
        }

        return $response->json();
    }

    /**
     * GET /payments/{reference}
     * Status polling fallback — the webhook is the primary confirmation path.
     */
    public function retrieve(string $reference): array
    {
        $response = Http::withHeaders(['Authorization' => $this->publicKey])
            ->get("{$this->baseUrl}/payments/{$reference}");

        if ($response->failed()) {
            throw new RuntimeException("NotchPay retrieve failed: {$response->body()}");
        }

        return $response->json();
    }
}
