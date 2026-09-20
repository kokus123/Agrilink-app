<?php

use App\Models\Commande;
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
    #[Title('Tableau de bord')]
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

        $agreger = function ($lignes, callable $valeur) use ($cles, $formatCle) {
            $somme = array_fill_keys($cles, 0.0);
            foreach ($lignes as $ligne) {
                $cle = Carbon::parse($ligne->created_at)->format($formatCle);
                if (isset($somme[$cle])) {
                    $somme[$cle] += $valeur($ligne);
                }
            }

            return array_values($somme);
        };

        $revenus = $agreger(
            Paiement::reussis()->where('created_at', '>=', $debut)->get(['montant', 'created_at']),
            fn ($p) => (float) $p->montant
        );
        $commandes = $agreger(
            Commande::where('created_at', '>=', $debut)->get(['id', 'created_at']),
            fn () => 1
        );
        $membres = $agreger(
            User::where('created_at', '>=', $debut)->get(['id', 'created_at']),
            fn () => 1
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

        $statuts = DB::table('commandes')
            ->select('statut', DB::raw('count(*) as total'))
            ->groupBy('statut')
            ->pluck('total', 'statut')
            ->all();

        $recents = User::latest()->take(5)->get()->map(function ($u) {
            $initiales = collect(preg_split('/\s+/', trim($u->name)))
                ->filter()
                ->take(2)
                ->map(fn ($p) => mb_strtoupper(mb_substr($p, 0, 1)))
                ->implode('');

            return [
                'id' => $u->id,
                'name' => $u->name,
                'email' => $u->email,
                'role' => $u->role,
                'actif' => (bool) $u->is_active,
                'initiales' => $initiales,
                'date' => $u->created_at->format('d/m/Y'),
            ];
        })->all();

        return [
            'periode' => $periode,
            'labels' => $labels,
            'titres' => $titres,
            'series' => [
                'revenus' => $construire($revenus),
                'commandes' => $construire($commandes),
                'membres' => $construire($membres),
            ],
            'agriculteurs' => User::role('agriculteur')->count(),
            'acheteurs' => User::role('acheteur')->count(),
            'transporteurs' => User::role('transporteur')->count(),
            'premium' => User::role('agriculteur')->abonnesPremium()->count(),
            'statuts' => $statuts,
            'recents' => $recents,
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

    $prenom = explode(' ', trim(auth()->user()->name))[0];

    $metriques = [
        'revenus'   => ['label' => 'Revenus',          'unite' => 'FCFA', 'couleur' => '#059669'],
        'commandes' => ['label' => 'Commandes',        'unite' => '',     'couleur' => '#0d9488'],
        'membres'   => ['label' => 'Nouveaux membres', 'unite' => '',     'couleur' => '#65a30d'],
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

    // Communauté
    $membresCommunaute = [
        ['label' => 'Agriculteurs',  'valeur' => $d['agriculteurs'],  'couleur' => '#059669'],
        ['label' => 'Acheteurs',     'valeur' => $d['acheteurs'],     'couleur' => '#2dd4bf'],
        ['label' => 'Transporteurs', 'valeur' => $d['transporteurs'], 'couleur' => '#a3e635'],
    ];
    $totalCommunaute = array_sum(array_column($membresCommunaute, 'valeur'));
    $tauxPremium = $d['agriculteurs'] > 0 ? round($d['premium'] / $d['agriculteurs'] * 100) : 0;

    // Commandes par statut
    $styleStatuts = [
        'en_attente'   => ['label' => 'En attente',   'couleur' => 'bg-amber-400'],
        'confirmee'    => ['label' => 'Confirmée',    'couleur' => 'bg-sky-500'],
        'en_livraison' => ['label' => 'En livraison', 'couleur' => 'bg-emerald-500'],
        'livree'       => ['label' => 'Livrée',       'couleur' => 'bg-emerald-800'],
        'annulee'      => ['label' => 'Annulée',      'couleur' => 'bg-rose-400'],
    ];
    $totalCommandes = array_sum($d['statuts']);
    $enCours = ($d['statuts']['en_attente'] ?? 0) + ($d['statuts']['confirmee'] ?? 0) + ($d['statuts']['en_livraison'] ?? 0);

    $styleRoles = [
        'agriculteur'  => 'bg-emerald-50 text-emerald-700',
        'acheteur'     => 'bg-sky-50 text-sky-700',
        'transporteur' => 'bg-amber-50 text-amber-700',
        'admin'        => 'bg-slate-100 text-slate-600',
    ];
@endphp

<div class="mx-auto max-w-7xl space-y-6">

    {{-- En-tête --}}
    <div>
        <h2 class="text-2xl font-semibold tracking-tight text-slate-900">Bonjour, {{ $prenom }}</h2>
        <p class="mt-1 text-sm text-slate-500">Voici où en est Agrilink. Cliquez sur une carte pour changer la courbe.</p>
    </div>

    <div x-data="{ metric: 'revenus', i: null, titres: { revenus: 'Revenus', commandes: 'Commandes', membres: 'Nouveaux membres' } }" class="space-y-6">

        {{-- Cartes chiffres (les 3 premières pilotent la courbe) --}}
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

            {{-- Premium (information, ne pilote pas la courbe) --}}
            <div class="rounded-2xl border border-slate-200/70 bg-white p-5">
                <span class="text-sm text-slate-500">Abonnés Premium</span>
                <p class="mt-3 text-2xl font-semibold tabular-nums tracking-tight text-slate-900">{{ $fmt($d['premium']) }}</p>

                <div class="mt-[1.65rem] h-1.5 overflow-hidden rounded-full bg-slate-100">
                    <div class="h-full rounded-full bg-emerald-600" style="width: {{ $tauxPremium }}%"></div>
                </div>
                <p class="mt-2 text-xs text-slate-400">{{ $tauxPremium }} % des {{ $fmt($d['agriculteurs']) }} agriculteurs</p>
            </div>
        </section>

        {{-- Courbe principale + communauté --}}
        <section class="grid gap-4 lg:grid-cols-3">

            <div class="relative rounded-2xl border border-slate-200/70 bg-white p-5 sm:p-6 lg:col-span-2">

                <div class="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
                    <div>
                        <h3 class="text-base font-semibold text-slate-900" x-text="titres[metric]">Revenus</h3>
                        <p class="mt-0.5 text-sm text-slate-500">{{ $textePeriode[$d['periode']] }}</p>
                    </div>

                    <div class="flex items-center gap-2">
                        {{-- Choix de la période --}}
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

                        {{-- Actualiser --}}
                        <button type="button"
                                wire:click="actualiser"
                                wire:loading.attr="disabled"
                                wire:target="actualiser"
                                aria-label="Actualiser les données"
                                title="Actualiser"
                                class="inline-flex h-9 w-9 items-center justify-center rounded-xl border border-slate-200 text-slate-500 transition hover:bg-slate-50 hover:text-slate-800 disabled:cursor-wait disabled:opacity-60">
                            <svg wire:loading.class="animate-spin" wire:target="actualiser" class="h-4 w-4 motion-reduce:animate-none" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"/></svg>
                        </button>
                    </div>
                </div>

                {{-- Zone du graphique --}}
                <div class="relative mt-6">

                    {{-- Chargement --}}
                    <div wire:loading.flex
                         wire:target="periode,actualiser"
                         class="absolute inset-0 z-20 hidden items-center justify-center rounded-xl bg-white/70 backdrop-blur-[1px]">
                        <svg class="h-6 w-6 animate-spin text-emerald-600 motion-reduce:animate-none" viewBox="0 0 24 24" fill="none"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"/><path class="opacity-90" fill="currentColor" d="M4 12a8 8 0 018-8v4a4 4 0 00-4 4H4z"/></svg>
                    </div>

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

                                    {{-- Lignes de repère --}}
                                    <div class="absolute inset-x-0 border-t border-dashed border-slate-200" style="top: 12%"></div>
                                    <div class="absolute inset-x-0 border-t border-dashed border-slate-200" style="top: 52%"></div>
                                    <div class="absolute inset-x-0 border-t border-slate-200" style="top: 92%"></div>

                                    {{-- Courbe --}}
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

                                    {{-- Zones de survol + infobulle --}}
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

                                    {{-- Aucune donnée --}}
                                    @if ($vide)
                                        <div class="absolute inset-0 flex items-center justify-center">
                                            <p class="rounded-lg bg-white/90 px-3 py-1.5 text-sm text-slate-500">Aucune donnée sur cette période</p>
                                        </div>
                                    @endif
                                </div>
                            </div>

                            {{-- Axe horizontal --}}
                            <div class="ml-12 mt-2 flex justify-between text-xs text-slate-400">
                                @foreach ($indexEtiquettes as $idx)
                                    <span>{{ $d['labels'][$idx] }}</span>
                                @endforeach
                            </div>
                        </div>
                    @endforeach
                </div>
            </div>

            {{-- Communauté --}}
            <div class="rounded-2xl border border-slate-200/70 bg-white p-5 sm:p-6">
                <h3 class="text-base font-semibold text-slate-900">Communauté</h3>
                <p class="mt-0.5 text-sm text-slate-500">Répartition des comptes</p>

                <div class="relative mx-auto mt-6 h-40 w-40">
                    <svg viewBox="0 0 42 42" class="h-full w-full -rotate-90" aria-hidden="true">
                        <circle cx="21" cy="21" r="15.9155" fill="none" stroke="#f1f5f9" stroke-width="5"/>
                        @php $cumul = 0; @endphp
                        @foreach ($membresCommunaute as $c)
                            @php $part = $totalCommunaute > 0 ? $c['valeur'] / $totalCommunaute * 100 : 0; @endphp
                            @if ($part > 0)
                                <circle cx="21" cy="21" r="15.9155" fill="none"
                                        stroke="{{ $c['couleur'] }}" stroke-width="5"
                                        stroke-dasharray="{{ round($part, 2) }} {{ round(100 - $part, 2) }}"
                                        stroke-dashoffset="{{ -round($cumul, 2) }}"/>
                            @endif
                            @php $cumul += $part; @endphp
                        @endforeach
                    </svg>
                    <div class="absolute inset-0 flex flex-col items-center justify-center">
                        <span class="text-2xl font-semibold tabular-nums text-slate-900">{{ $fmt($totalCommunaute) }}</span>
                        <span class="text-xs text-slate-400">comptes</span>
                    </div>
                </div>

                <ul class="mt-6 space-y-3">
                    @foreach ($membresCommunaute as $c)
                        <li class="flex items-center gap-3 text-sm">
                            <span class="h-2.5 w-2.5 shrink-0 rounded-full" style="background: {{ $c['couleur'] }}"></span>
                            <span class="flex-1 text-slate-600">{{ $c['label'] }}</span>
                            <span class="font-semibold tabular-nums text-slate-900">{{ $fmt($c['valeur']) }}</span>
                        </li>
                    @endforeach
                </ul>
            </div>
        </section>
    </div>

    {{-- Commandes par statut + derniers inscrits --}}
    <section class="grid gap-4 lg:grid-cols-3">

        <div class="rounded-2xl border border-slate-200/70 bg-white p-5 sm:p-6">
            <h3 class="text-base font-semibold text-slate-900">Commandes</h3>
            <p class="mt-0.5 text-sm text-slate-500">{{ $fmt($enCours) }} en cours sur {{ $fmt($totalCommandes) }}</p>

            @if ($totalCommandes > 0)
                <ul class="mt-5 space-y-4">
                    @foreach ($d['statuts'] as $statut => $total)
                        @php
                            $couleur = $styleStatuts[$statut]['couleur'] ?? 'bg-slate-400';
                            $label = $styleStatuts[$statut]['label'] ?? ucfirst(str_replace('_', ' ', $statut));
                            $part = round($total / $totalCommandes * 100);
                        @endphp
                        <li>
                            <div class="flex items-center justify-between text-sm">
                                <span class="text-slate-600">{{ $label }}</span>
                                <span class="font-semibold tabular-nums text-slate-900">{{ $fmt($total) }}</span>
                            </div>
                            <div class="mt-1.5 h-1.5 overflow-hidden rounded-full bg-slate-100">
                                <div class="h-full rounded-full {{ $couleur }}" style="width: {{ $part }}%"></div>
                            </div>
                        </li>
                    @endforeach
                </ul>
            @else
                <div class="mt-5 rounded-xl bg-slate-50 px-4 py-8 text-center">
                    <p class="text-sm font-medium text-slate-600">Aucune commande pour l'instant</p>
                    <p class="mt-1 text-sm text-slate-400">Elles s'afficheront ici dès la première.</p>
                </div>
            @endif
        </div>

        <div class="rounded-2xl border border-slate-200/70 bg-white p-5 sm:p-6 lg:col-span-2">
            <div class="flex items-start justify-between gap-4">
                <div>
                    <h3 class="text-base font-semibold text-slate-900">Derniers inscrits</h3>
                    <p class="mt-0.5 text-sm text-slate-500">Les 5 comptes les plus récents</p>
                </div>
                <a href="{{ route('admin.utilisateurs') }}" wire:navigate
                   class="rounded-lg px-2 py-1 text-sm font-medium text-emerald-700 transition hover:bg-emerald-50 hover:text-emerald-900">
                    Voir tout
                </a>
            </div>

            <ul class="mt-3 divide-y divide-slate-100">
                @forelse ($d['recents'] as $u)
                    <li class="flex items-center gap-3 py-3" wire:key="recent-{{ $u['id'] }}">
                        <span class="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-emerald-100 text-xs font-semibold text-emerald-800">{{ $u['initiales'] }}</span>

                        <div class="min-w-0 flex-1">
                            <p class="truncate text-sm font-medium text-slate-900">{{ $u['name'] }}</p>
                            <p class="truncate text-xs text-slate-400">{{ $u['email'] }}</p>
                        </div>

                        <span class="hidden rounded-full px-2.5 py-1 text-xs font-medium capitalize sm:inline-flex {{ $styleRoles[$u['role']] ?? 'bg-slate-100 text-slate-600' }}">{{ $u['role'] }}</span>

                        @if ($u['actif'])
                            <span class="inline-flex items-center gap-1.5 text-xs font-medium text-emerald-700">
                                <span class="h-1.5 w-1.5 rounded-full bg-emerald-500"></span>Actif
                            </span>
                        @else
                            <span class="inline-flex items-center gap-1.5 text-xs font-medium text-rose-700">
                                <span class="h-1.5 w-1.5 rounded-full bg-rose-500"></span>Bloqué
                            </span>
                        @endif

                        <span class="hidden w-20 text-right text-xs tabular-nums text-slate-400 md:block">{{ $u['date'] }}</span>
                    </li>
                @empty
                    <li class="py-10 text-center text-sm text-slate-400">Aucun utilisateur inscrit pour l'instant.</li>
                @endforelse
            </ul>
        </div>
    </section>

</div>