<?php

use App\Models\Commande;
use App\Models\Livraison;
use App\Models\Paiement;
use App\Models\User;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Livewire\Attributes\Computed;
use Livewire\Attributes\Layout;
use Livewire\Attributes\Title;
use Livewire\Attributes\Url;
use Livewire\Component;

new
    #[Layout('components.layouts.admin')]
    #[Title('Statistiques')]
    class extends Component {

    /** 7j | 30j | 6m | 12m */
    #[Url(as: 'periode')]
    public string $periode = '30j';

    /** Bouton « Actualiser » : toute requête Livewire recalcule les données. */
    public function actualiser(): void
    {
    }

    #[Computed]
    public function donnees(): array
    {
        $periode = in_array($this->periode, ['7j', '30j', '6m', '12m'], true) ? $this->periode : '30j';

        [$n, $pas] = match ($periode) {
            '7j' => [7, 'jour'],
            '30j' => [30, 'jour'],
            '6m' => [6, 'mois'],
            '12m' => [12, 'mois'],
        };

        $formatCle = $pas === 'jour' ? 'Y-m-d' : 'Y-m';

        // 2 périodes consécutives : la précédente (pour la comparaison) puis l'actuelle
        $intervalles = [];
        for ($i = 2 * $n - 1; $i >= 0; $i--) {
            $intervalles[] = $pas === 'jour'
                ? now()->startOfDay()->subDays($i)
                : now()->startOfMonth()->subMonths($i);
        }

        $cles = array_map(fn ($d) => $d->format($formatCle), $intervalles);
        $debut = $intervalles[0];
        $debutCourant = $intervalles[$n];

        $agreger = function ($lignes, callable $valeur, string $champ = 'created_at') use ($cles, $formatCle) {
            $somme = array_fill_keys($cles, 0.0);
            foreach ($lignes as $ligne) {
                if (! $ligne->{$champ}) {
                    continue;
                }
                $cle = Carbon::parse($ligne->{$champ})->format($formatCle);
                if (isset($somme[$cle])) {
                    $somme[$cle] += $valeur($ligne);
                }
            }

            return array_values($somme);
        };

        // Commandes non annulées = base du volume des ventes
        $commandes = Commande::where('created_at', '>=', $debut)
            ->where('statut', '!=', 'annulee')
            ->get(['id', 'montant_total', 'created_at']);

        $ventes = $agreger($commandes, fn ($c) => (float) $c->montant_total);
        $nbCommandes = $agreger($commandes, fn () => 1);

        $livraisons = $agreger(
            Livraison::where('statut', 'livree')
                ->whereNotNull('date_livraison_reelle')
                ->where('date_livraison_reelle', '>=', $debut)
                ->get(['id', 'date_livraison_reelle']),
            fn () => 1,
            'date_livraison_reelle'
        );

        $construire = function (array $valeurs) use ($n) {
            $courant = array_slice($valeurs, $n);
            $precedent = array_slice($valeurs, 0, $n);
            $totalCourant = array_sum($courant);
            $totalPrecedent = array_sum($precedent);

            return [
                'valeurs' => $courant,
                'total' => $totalCourant,
                'delta' => $totalPrecedent > 0
                    ? (int) round(($totalCourant - $totalPrecedent) / $totalPrecedent * 100)
                    : null,
                'courbe' => $this->courbe($courant),
            ];
        };

        // Panier moyen = volume des ventes / nombre de commandes
        $ventesCourant = array_sum(array_slice($ventes, $n));
        $ventesPrecedent = array_sum(array_slice($ventes, 0, $n));
        $commandesCourant = array_sum(array_slice($nbCommandes, $n));
        $commandesPrecedent = array_sum(array_slice($nbCommandes, 0, $n));

        $panier = $commandesCourant > 0 ? $ventesCourant / $commandesCourant : 0;
        $panierPrecedent = $commandesPrecedent > 0 ? $ventesPrecedent / $commandesPrecedent : 0;

        // Étiquettes de l'axe horizontal et infobulles
        $courants = array_slice($intervalles, $n);

        $labels = array_map(function ($d) use ($periode) {
            $d = $d->copy()->locale('fr');

            return match ($periode) {
                '7j' => $d->translatedFormat('D j'),
                '30j' => $d->translatedFormat('j M'),
                default => $d->translatedFormat('M'),
            };
        }, $courants);

        $titres = array_map(function ($d) use ($pas) {
            $d = $d->copy()->locale('fr');

            return $pas === 'jour' ? $d->translatedFormat('l j F Y') : $d->translatedFormat('F Y');
        }, $courants);

        // Ventes par catégorie et par agriculteur (quantité x prix unitaire, période actuelle)
        $commandesPeriode = Commande::where('created_at', '>=', $debutCourant)
            ->where('statut', '!=', 'annulee')
            ->with('produits:id,agriculteur_id,categorie')
            ->get(['id']);

        $parCategorie = [];
        $parAgriculteur = [];

        foreach ($commandesPeriode as $commande) {
            foreach ($commande->produits as $produit) {
                $montant = (float) $produit->pivot->quantite * (float) $produit->pivot->prix_unitaire;
                $categorie = $produit->categorie ?: 'Autres';

                $parCategorie[$categorie] = ($parCategorie[$categorie] ?? 0) + $montant;
                $parAgriculteur[$produit->agriculteur_id] = ($parAgriculteur[$produit->agriculteur_id] ?? 0) + $montant;
            }
        }

        arsort($parCategorie);
        arsort($parAgriculteur);

        $totalCategories = array_sum($parCategorie);
        $categories = [];
        $autres = 0;
        $rang = 0;
        foreach ($parCategorie as $nom => $montant) {
            if ($rang < 5) {
                $categories[] = ['label' => ucfirst((string) $nom), 'montant' => $montant];
            } else {
                $autres += $montant;
            }
            $rang++;
        }
        if ($autres > 0) {
            $categories[] = ['label' => 'Autres', 'montant' => $autres];
        }
        $categories = array_map(fn ($c) => $c + [
            'part' => $totalCategories > 0 ? (int) round($c['montant'] / $totalCategories * 100) : 0,
        ], $categories);

        $topMontants = array_slice($parAgriculteur, 0, 5, true);
        $noms = $topMontants ? User::whereIn('id', array_keys($topMontants))->pluck('name', 'id') : collect();
        $notes = $topMontants
            ? DB::table('notations')
                ->whereIn('agriculteur_id', array_keys($topMontants))
                ->select('agriculteur_id', DB::raw('avg(note) as moyenne'))
                ->groupBy('agriculteur_id')
                ->pluck('moyenne', 'agriculteur_id')
            : collect();

        $top = [];
        foreach ($topMontants as $id => $montant) {
            $top[] = [
                'nom' => $noms[$id] ?? 'Compte supprimé',
                'ventes' => $montant,
                'note' => isset($notes[$id]) ? round((float) $notes[$id], 1) : null,
            ];
        }

        $noteGlobale = DB::table('notations')->selectRaw('avg(note) as moyenne, count(*) as total')->first();

        // Paiements Mobile Money réussis par opérateur (période actuelle)
        $operateurs = ['mtn' => 0, 'orange' => 0, 'autre' => 0];
        foreach (Paiement::reussis()->where('created_at', '>=', $debutCourant)->get(['methode']) as $paiement) {
            $methode = strtolower((string) $paiement->methode);
            $operateurs[in_array($methode, ['mtn', 'orange'], true) ? $methode : 'autre']++;
        }

        return [
            'periode' => $periode,
            'labels' => $labels,
            'titres' => $titres,
            'series' => [
                'ventes' => $construire($ventes),
                'commandes' => $construire($nbCommandes),
                'livraisons' => $construire($livraisons),
            ],
            'panier' => [
                'valeur' => $panier,
                'delta' => $panierPrecedent > 0 ? (int) round(($panier - $panierPrecedent) / $panierPrecedent * 100) : null,
            ],
            'categories' => $categories,
            'top' => $top,
            'note_globale' => [
                'moyenne' => $noteGlobale && $noteGlobale->moyenne !== null ? round((float) $noteGlobale->moyenne, 1) : null,
                'total' => (int) ($noteGlobale->total ?? 0),
            ],
            'operateurs' => $operateurs,
        ];
    }

    /**
     * Transforme une liste de valeurs en courbe SVG lissée (viewBox 0..100).
     * Zéro = y 92, maximum = y 12.
     */
    private function courbe(array $valeurs): array
    {
        $n = count($valeurs);
        $max = max(1, max($valeurs));

        $points = [];
        foreach ($valeurs as $i => $v) {
            $x = $n > 1 ? $i / ($n - 1) * 100 : 50;
            $y = 92 - ($v / $max) * 80;
            $points[] = [round($x, 2), round($y, 2)];
        }

        $ligne = 'M' . $points[0][0] . ',' . $points[0][1];
        for ($i = 1; $i < $n; $i++) {
            $xm = round(($points[$i - 1][0] + $points[$i][0]) / 2, 2);
            $ligne .= ' C' . $xm . ',' . $points[$i - 1][1]
                . ' ' . $xm . ',' . $points[$i][1]
                . ' ' . $points[$i][0] . ',' . $points[$i][1];
        }

        return [
            'ligne' => $ligne,
            'aire' => $ligne . ' L100,100 L0,100 Z',
            'points' => $points,
            'max' => $max,
        ];
    }
};
?>

@php
    $d = $this->donnees;

    $fmt = fn ($n) => number_format((float) $n, 0, ',', ' ');
    $compact = function ($n) {
        $n = (float) $n;
        if ($n >= 1000000) {
            return rtrim(rtrim(number_format($n / 1000000, 1, ',', ''), '0'), ',') . ' M';
        }
        if ($n >= 1000) {
            return rtrim(rtrim(number_format($n / 1000, 1, ',', ''), '0'), ',') . ' k';
        }

        return (string) round($n);
    };

    $metriques = [
        'ventes'     => ['label' => 'Volume des ventes',   'unite' => 'FCFA', 'couleur' => '#059669'],
        'commandes'  => ['label' => 'Commandes',           'unite' => '',     'couleur' => '#0d9488'],
        'livraisons' => ['label' => 'Livraisons réussies', 'unite' => '',     'couleur' => '#65a30d'],
    ];

    $periodes = ['7j' => '7 j', '30j' => '30 j', '6m' => '6 mois', '12m' => '12 mois'];
    $textePeriode = [
        '7j'  => 'Les 7 derniers jours',
        '30j' => 'Les 30 derniers jours',
        '6m'  => 'Les 6 derniers mois',
        '12m' => 'Les 12 derniers mois',
    ];

    // Étiquettes de l'axe horizontal (6 maximum pour rester lisible)
    $nbPoints = count($d['labels']);
    $nbEtiquettes = $nbPoints <= 7 ? $nbPoints : 6;
    $indexEtiquettes = collect(range(0, $nbEtiquettes - 1))
        ->map(fn ($k) => (int) round($k * ($nbPoints - 1) / max(1, $nbEtiquettes - 1)))
        ->unique()
        ->values()
        ->all();

    // Mobile Money
    $libellesOperateurs = [
        'mtn'    => ['label' => 'MTN Mobile Money', 'couleur' => '#facc15'],
        'orange' => ['label' => 'Orange Money',     'couleur' => '#f97316'],
        'autre'  => ['label' => 'Autre',            'couleur' => '#94a3b8'],
    ];
    $totalPaiements = array_sum($d['operateurs']);
    $operateursAffiches = array_filter($d['operateurs'], fn ($v) => $v > 0);

    $noteGlobale = $d['note_globale'];
@endphp

<div class="mx-auto max-w-7xl space-y-6">

    {{-- En-tête + période --}}
    <div class="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
        <div>
            <h2 class="text-2xl font-semibold tracking-tight text-slate-900">Statistiques</h2>
            <p class="mt-1 text-sm text-slate-500">{{ $textePeriode[$d['periode']] }}, comparés à la période précédente. Les commandes annulées ne sont pas comptées.</p>
        </div>

        <div class="flex items-center gap-2">
            <svg wire:loading wire:target="periode,actualiser" class="h-4 w-4 animate-spin text-emerald-600 motion-reduce:animate-none" viewBox="0 0 24 24" fill="none"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"/><path class="opacity-90" fill="currentColor" d="M4 12a8 8 0 018-8v4a4 4 0 00-4 4H4z"/></svg>

            <div class="inline-flex rounded-xl bg-slate-100 p-1">
                @foreach ($periodes as $valeur => $libelle)
                    <button type="button"
                            wire:click="$set('periode', '{{ $valeur }}')"
                            wire:loading.attr="disabled"
                            wire:target="periode"
                            class="rounded-lg px-3 py-1.5 text-sm font-medium transition disabled:cursor-wait {{ $d['periode'] === $valeur ? 'bg-white text-emerald-800 shadow-sm' : 'text-slate-500 hover:text-slate-800' }}">
                        {{ $libelle }}
                    </button>
                @endforeach
            </div>

            <button type="button"
                    wire:click="actualiser"
                    wire:loading.attr="disabled"
                    wire:target="actualiser"
                    aria-label="Actualiser les données"
                    title="Actualiser"
                    class="inline-flex h-9 w-9 items-center justify-center rounded-xl border border-slate-200 bg-white text-slate-500 transition hover:bg-slate-50 hover:text-slate-800 disabled:cursor-wait disabled:opacity-60">
                <svg wire:loading.class="animate-spin" wire:target="actualiser" class="h-4 w-4 motion-reduce:animate-none" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"/></svg>
            </button>
        </div>
    </div>

    <div class="space-y-6 transition-opacity" wire:loading.class="opacity-60" wire:target="periode,actualiser">

        {{-- Cartes chiffres + courbe (les 3 premières cartes pilotent la courbe) --}}
        <div x-data="{ metric: 'ventes', i: null, titres: { ventes: 'Volume des ventes', commandes: 'Commandes', livraisons: 'Livraisons réussies' } }" class="space-y-6">

            <section class="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">

                @foreach ($metriques as $cle => $m)
                    @php
                        $s = $d['series'][$cle];
                        $delta = $s['delta'];
                    @endphp
                    <button type="button"
                            @click="metric = '{{ $cle }}'; i = null"
                            :aria-pressed="metric === '{{ $cle }}'"
                            :class="metric === '{{ $cle }}' ? 'border-emerald-500 ring-4 ring-emerald-500/10' : 'border-slate-200/70 hover:border-slate-300'"
                            class="rounded-2xl border bg-white p-5 text-left transition focus:outline-none focus-visible:ring-4 focus-visible:ring-emerald-500/20">
                        <div class="flex items-center justify-between gap-2">
                            <span class="text-sm text-slate-500">{{ $m['label'] }}</span>

                            @if ($delta !== null)
                                <span title="Par rapport à la période précédente"
                                      class="inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium {{ $delta >= 0 ? 'bg-emerald-50 text-emerald-700' : 'bg-rose-50 text-rose-700' }}">
                                    {{ $delta >= 0 ? '↑' : '↓' }} {{ abs($delta) }} %
                                </span>
                            @elseif ($s['total'] > 0)
                                <span class="inline-flex items-center rounded-full bg-emerald-50 px-2 py-0.5 text-xs font-medium text-emerald-700">Nouveau</span>
                            @endif
                        </div>

                        <p class="mt-3 text-2xl font-semibold tabular-nums tracking-tight text-slate-900">
                            {{ $fmt($s['total']) }}
                            @if ($m['unite'])
                                <span class="text-sm font-medium text-slate-400">{{ $m['unite'] }}</span>
                            @endif
                        </p>

                        <svg class="mt-3 h-9 w-full overflow-visible" viewBox="0 0 100 100" preserveAspectRatio="none" aria-hidden="true">
                            <path d="{{ $s['courbe']['ligne'] }}" fill="none" stroke="{{ $m['couleur'] }}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" vector-effect="non-scaling-stroke"/>
                        </svg>
                    </button>
                @endforeach

                {{-- Panier moyen (information, ne pilote pas la courbe) --}}
                <div class="rounded-2xl border border-slate-200/70 bg-white p-5">
                    <div class="flex items-center justify-between gap-2">
                        <span class="text-sm text-slate-500">Panier moyen</span>
                        @if ($d['panier']['delta'] !== null)
                            <span title="Par rapport à la période précédente"
                                  class="inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium {{ $d['panier']['delta'] >= 0 ? 'bg-emerald-50 text-emerald-700' : 'bg-rose-50 text-rose-700' }}">
                                {{ $d['panier']['delta'] >= 0 ? '↑' : '↓' }} {{ abs($d['panier']['delta']) }} %
                            </span>
                        @endif
                    </div>
                    <p class="mt-3 text-2xl font-semibold tabular-nums tracking-tight text-slate-900">
                        {{ $fmt($d['panier']['valeur']) }}
                        <span class="text-sm font-medium text-slate-400">FCFA</span>
                    </p>
                    <p class="mt-[1.65rem] text-xs text-slate-400">Volume des ventes ÷ nombre de commandes</p>
                </div>
            </section>

            {{-- Courbe + Mobile Money --}}
            <section class="grid gap-4 lg:grid-cols-3">

                <div class="rounded-2xl border border-slate-200/70 bg-white p-5 sm:p-6 lg:col-span-2">
                    <h3 class="text-base font-semibold text-slate-900" x-text="titres[metric]">Volume des ventes</h3>
                    <p class="mt-0.5 text-sm text-slate-500">{{ $textePeriode[$d['periode']] }}</p>

                    <div class="mt-6">
                        @foreach ($metriques as $cle => $m)
                            @php
                                $s = $d['series'][$cle];
                                $c = $s['courbe'];
                                $vide = $s['total'] <= 0;
                                $largeurZone = 100 / max(1, count($c['points']) - 1);
                            @endphp

                            <div x-show="metric === '{{ $cle }}'" @if (! $loop->first) x-cloak @endif>
                                <div class="relative h-72">

                                    {{-- Axe vertical --}}
                                    @unless ($vide)
                                        <span class="absolute left-0 -translate-y-1/2 text-xs tabular-nums text-slate-400" style="top: 12%">{{ $compact($c['max']) }}</span>
                                        @if ($c['max'] >= 4)
                                            <span class="absolute left-0 -translate-y-1/2 text-xs tabular-nums text-slate-400" style="top: 52%">{{ $compact($c['max'] / 2) }}</span>
                                        @endif
                                        <span class="absolute left-0 -translate-y-1/2 text-xs tabular-nums text-slate-400" style="top: 92%">0</span>
                                    @endunless

                                    <div class="absolute inset-y-0 left-12 right-0" @mouseleave="i = null">

                                        <div class="absolute inset-x-0 border-t border-dashed border-slate-200" style="top: 12%"></div>
                                        <div class="absolute inset-x-0 border-t border-dashed border-slate-200" style="top: 52%"></div>
                                        <div class="absolute inset-x-0 border-t border-slate-200" style="top: 92%"></div>

                                        <svg class="absolute inset-0 h-full w-full overflow-visible" viewBox="0 0 100 100" preserveAspectRatio="none" aria-hidden="true">
                                            <defs>
                                                <linearGradient id="degrade-{{ $cle }}" x1="0" y1="0" x2="0" y2="1">
                                                    <stop offset="0%" stop-color="{{ $m['couleur'] }}" stop-opacity="0.22"/>
                                                    <stop offset="100%" stop-color="{{ $m['couleur'] }}" stop-opacity="0"/>
                                                </linearGradient>
                                            </defs>
                                            <path d="{{ $c['aire'] }}" fill="url(#degrade-{{ $cle }})"/>
                                            <path d="{{ $c['ligne'] }}" fill="none" stroke="{{ $m['couleur'] }}" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" vector-effect="non-scaling-stroke"/>
                                        </svg>

                                        @foreach ($c['points'] as $k => [$px, $py])
                                            <div class="absolute inset-y-0 cursor-crosshair"
                                                 style="left: calc({{ $px }}% - {{ $largeurZone / 2 }}%); width: {{ $largeurZone }}%"
                                                 @mouseenter="i = {{ $k }}"
                                                 @touchstart.passive="i = {{ $k }}"></div>
                                        @endforeach

                                        @foreach ($c['points'] as $k => [$px, $py])
                                            @php
                                                $alignement = $px < 15 ? '' : ($px > 85 ? '-translate-x-full' : '-translate-x-1/2');
                                            @endphp
                                            <div x-show="i === {{ $k }}" x-cloak class="pointer-events-none absolute inset-0">
                                                <div class="absolute inset-y-0 w-px bg-slate-300/70" style="left: {{ $px }}%"></div>
                                                <span class="absolute h-3 w-3 -translate-x-1/2 -translate-y-1/2 rounded-full border-2 border-white shadow"
                                                      style="left: {{ $px }}%; top: {{ $py }}%; background: {{ $m['couleur'] }}"></span>
                                                <div class="absolute z-10 -translate-y-full whitespace-nowrap rounded-lg bg-emerald-950 px-3 py-2 text-xs text-white shadow-lg {{ $alignement }}"
                                                     style="left: {{ $px }}%; top: {{ $py }}%; margin-top: -14px">
                                                    <p class="text-emerald-200/80">{{ $d['titres'][$k] }}</p>
                                                    <p class="mt-0.5 font-semibold tabular-nums">{{ $fmt($s['valeurs'][$k]) }} {{ $m['unite'] }}</p>
                                                </div>
                                            </div>
                                        @endforeach

                                        @if ($vide)
                                            <div class="absolute inset-0 flex items-center justify-center">
                                                <p class="rounded-lg bg-white/90 px-3 py-1.5 text-sm text-slate-500">Aucune donnée sur cette période</p>
                                            </div>
                                        @endif
                                    </div>
                                </div>

                                <div class="ml-12 mt-2 flex justify-between text-xs text-slate-400">
                                    @foreach ($indexEtiquettes as $idx)
                                        <span>{{ $d['labels'][$idx] }}</span>
                                    @endforeach
                                </div>
                            </div>
                        @endforeach
                    </div>
                </div>

                {{-- Mobile Money --}}
                <div class="rounded-2xl border border-slate-200/70 bg-white p-5 sm:p-6">
                    <h3 class="text-base font-semibold text-slate-900">Paiements Mobile Money</h3>
                    <p class="mt-0.5 text-sm text-slate-500">Paiements réussis par opérateur</p>

                    @if ($totalPaiements > 0)
                        <div class="relative mx-auto mt-6 h-40 w-40">
                            <svg viewBox="0 0 42 42" class="h-full w-full -rotate-90" aria-hidden="true">
                                <circle cx="21" cy="21" r="15.9155" fill="none" stroke="#f1f5f9" stroke-width="5"/>
                                @php $cumul = 0; @endphp
                                @foreach ($operateursAffiches as $cle => $nb)
                                    @php $part = $nb / $totalPaiements * 100; @endphp
                                    <circle cx="21" cy="21" r="15.9155" fill="none"
                                            stroke="{{ $libellesOperateurs[$cle]['couleur'] }}" stroke-width="5"
                                            stroke-dasharray="{{ round($part, 2) }} {{ round(100 - $part, 2) }}"
                                            stroke-dashoffset="{{ -round($cumul, 2) }}"/>
                                    @php $cumul += $part; @endphp
                                @endforeach
                            </svg>
                            <div class="absolute inset-0 flex flex-col items-center justify-center">
                                <span class="text-2xl font-semibold tabular-nums text-slate-900">{{ $fmt($totalPaiements) }}</span>
                                <span class="text-xs text-slate-400">paiements</span>
                            </div>
                        </div>

                        <ul class="mt-6 space-y-3">
                            @foreach ($operateursAffiches as $cle => $nb)
                                <li class="flex items-center gap-3 text-sm" wire:key="operateur-{{ $cle }}">
                                    <span class="h-2.5 w-2.5 shrink-0 rounded-full" style="background: {{ $libellesOperateurs[$cle]['couleur'] }}"></span>
                                    <span class="flex-1 text-slate-600">{{ $libellesOperateurs[$cle]['label'] }}</span>
                                    <span class="font-semibold tabular-nums text-slate-900">{{ $fmt($nb) }}</span>
                                    <span class="w-10 text-right text-xs tabular-nums text-slate-400">{{ round($nb / $totalPaiements * 100) }} %</span>
                                </li>
                            @endforeach
                        </ul>
                    @else
                        <div class="mt-6 flex h-56 flex-col items-center justify-center rounded-xl bg-slate-50 px-4 text-center">
                            <p class="text-sm font-medium text-slate-600">Aucun paiement réussi</p>
                            <p class="mt-1 text-sm text-slate-400">Les paiements de la période apparaîtront ici.</p>
                        </div>
                    @endif
                </div>
            </section>
        </div>

        {{-- Catégories + meilleurs agriculteurs --}}
        <section class="grid gap-4 lg:grid-cols-2">

            <div class="rounded-2xl border border-slate-200/70 bg-white p-5 sm:p-6">
                <h3 class="text-base font-semibold text-slate-900">Ventes par catégorie</h3>
                <p class="mt-0.5 text-sm text-slate-500">Part de chaque catégorie dans le volume des ventes</p>

                @if (count($d['categories']) > 0)
                    <ul class="mt-5 space-y-4">
                        @foreach ($d['categories'] as $cat)
                            <li wire:key="categorie-{{ $loop->index }}">
                                <div class="flex items-center justify-between gap-3 text-sm">
                                    <span class="truncate text-slate-600">{{ $cat['label'] }}</span>
                                    <span class="shrink-0 tabular-nums">
                                        <span class="font-semibold text-slate-900">{{ $fmt($cat['montant']) }}</span>
                                        <span class="text-xs text-slate-400">FCFA · {{ $cat['part'] }} %</span>
                                    </span>
                                </div>
                                <div class="mt-1.5 h-1.5 overflow-hidden rounded-full bg-slate-100">
                                    <div class="h-full rounded-full bg-emerald-600" style="width: {{ $cat['part'] }}%"></div>
                                </div>
                            </li>
                        @endforeach
                    </ul>
                @else
                    <div class="mt-5 rounded-xl bg-slate-50 px-4 py-12 text-center">
                        <p class="text-sm font-medium text-slate-600">Aucune vente sur cette période</p>
                        <p class="mt-1 text-sm text-slate-400">Les catégories apparaîtront dès la première commande.</p>
                    </div>
                @endif
            </div>

            <div class="rounded-2xl border border-slate-200/70 bg-white p-5 sm:p-6">
                <div class="flex items-start justify-between gap-4">
                    <div>
                        <h3 class="text-base font-semibold text-slate-900">Meilleurs agriculteurs</h3>
                        <p class="mt-0.5 text-sm text-slate-500">Par montant des ventes</p>
                    </div>
                    @if ($noteGlobale['moyenne'] !== null)
                        <span class="shrink-0 rounded-full bg-emerald-50 px-2.5 py-1 text-xs font-medium text-emerald-700" title="Note moyenne de tous les avis">
                            ★ {{ str_replace('.', ',', $noteGlobale['moyenne']) }} · {{ $noteGlobale['total'] }} avis
                        </span>
                    @endif
                </div>

                @if (count($d['top']) > 0)
                    <ul class="mt-3 divide-y divide-slate-100">
                        @foreach ($d['top'] as $i => $a)
                            <li class="flex items-center gap-3 py-3" wire:key="top-{{ $i }}">
                                <span class="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-emerald-50 text-xs font-semibold text-emerald-800">{{ $i + 1 }}</span>
                                <p class="min-w-0 flex-1 truncate text-sm font-medium text-slate-900">{{ $a['nom'] }}</p>
                                @if ($a['note'] !== null)
                                    <span class="hidden text-xs tabular-nums text-slate-400 sm:inline">★ {{ str_replace('.', ',', $a['note']) }}</span>
                                @endif
                                <span class="text-sm font-semibold tabular-nums text-slate-900">{{ $fmt($a['ventes']) }} <span class="text-xs font-normal text-slate-400">FCFA</span></span>
                            </li>
                        @endforeach
                    </ul>
                @else
                    <div class="mt-5 rounded-xl bg-slate-50 px-4 py-12 text-center">
                        <p class="text-sm font-medium text-slate-600">Aucune vente sur cette période</p>
                        <p class="mt-1 text-sm text-slate-400">Le classement apparaîtra dès la première commande.</p>
                    </div>
                @endif
            </div>
        </section>
    </div>

</div>