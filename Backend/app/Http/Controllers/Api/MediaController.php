<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpFoundation\Response;

class MediaController extends Controller
{
    /**
     * GET /api/media/{path}
     *
     * Sert les fichiers du disque 'public' (photos produits, photos de
     * profil) en passant explicitement par Laravel plutôt que par le
     * fichier statique servi directement par `php artisan serve`.
     *
     * Nécessaire car le serveur de dev PHP intégré (utilisé par
     * `php artisan serve`) sert tout fichier existant dans storage/ en
     * statique, en contournant totalement Laravel — donc même avec
     * config/cors.php bien configuré, aucun header CORS n'était jamais
     * ajouté. En passant par une route qui ne correspond à aucun fichier
     * réel sur disque, la requête est forcée à traverser Laravel, où on
     * peut ajouter le header nous-mêmes.
     */
    public function show(string $path): Response
    {
        abort_unless(Storage::disk('public')->exists($path), 404);

        $fullPath = Storage::disk('public')->path($path);
        $mimeType = Storage::disk('public')->mimeType($path) ?? 'application/octet-stream';

        return response(file_get_contents($fullPath), 200, [
            'Content-Type' => $mimeType,
            'Access-Control-Allow-Origin' => '*',
            'Cache-Control' => 'public, max-age=86400',
        ]);
    }
}
