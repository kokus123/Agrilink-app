<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use RuntimeException;

/**
 * Client pour l'API Gemini (Google) — https://ai.google.dev/api/generate-content
 *
 * Utilise le mode JSON structuré (responseSchema) pour garantir une réponse
 * exploitable directement par le contrôleur, plutôt que d'avoir à parser du
 * texte libre.
 */
class GeminiService
{
    private string $baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
    private string $model = 'gemini-3.8-flash';

    public function __construct(private readonly string $apiKey)
    {
    }

    /**
     * Envoie un prompt et force une réponse JSON conforme au schéma fourni.
     * $schema suit le format Gemini (OBJECT/STRING/NUMBER/INTEGER/ARRAY...).
     *
     * @return array Le JSON décodé de la réponse du modèle.
     */
    public function genererJson(string $prompt, array $schema): array
    {
        $response = Http::withHeaders([
                'x-goog-api-key' => $this->apiKey,
                'Content-Type' => 'application/json',
            ])
            ->timeout(30)
            ->post("{$this->baseUrl}/models/{$this->model}:generateContent", [
                'contents' => [
                    ['parts' => [['text' => $prompt]]],
                ],
                'generationConfig' => [
                    'response_mime_type' => 'application/json',
                    'response_schema' => $schema,
                    'temperature' => 0.4,
                ],
            ]);

        if ($response->failed()) {
            throw new RuntimeException("Erreur API Gemini : {$response->body()}");
        }

        $text = $response->json('candidates.0.content.parts.0.text');

        if (! $text) {
            throw new RuntimeException('Réponse Gemini vide ou dans un format inattendu.');
        }

        $decoded = json_decode($text, true);

        if (! is_array($decoded)) {
            throw new RuntimeException('Réponse Gemini non exploitable (JSON invalide).');
        }

        return $decoded;
    }
}
