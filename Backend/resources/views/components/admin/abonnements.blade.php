<?php

use App\Models\Paiement;
use App\Models\User;
use Livewire\Attributes\Computed;
use Livewire\Attributes\Layout;
use Livewire\Attributes\Title;
use Livewire\Attributes\Url;
use Livewire\Component;
use Livewire\WithPagination;

new
    #[Layout('components.layouts.admin')]
    #[Title('Abonnements')]
    class extends Component {
    use WithPagination;

    /** Forfait Premium unique — FCFA par mois (même valeur que AbonnementController). */
    public const TARIF_PREMIUM = 5000;

    /** abonnes | paiements */
    #[Url(as: 'vue')]
    public string $onglet = 'abonnes';

    #[Url(as: 'q', except: '')]
    public string $recherche = '';

    /** tous | en_attente | reussi | echoue (onglet paiements) */
    #[Url(as: 'statut', except: 'tous')]
    public string $statutPaiement = 'tous';

    public function updatedOnglet(): void
    {
        $this->resetPage();
    }

    public function updatedRecherche(): void
    {
        $this->resetPage();
    }

    public function updatedStatutPaiement(): void
    {
        $this->resetPage();
    }

    #[Computed]
    public function kpis(): array
    {
        $maintenant = now();

        $revenusAbonnements = fn () => Paiement::reussis()->where('type', 'abonnement');

        return [
            'actifs' => User::where('is_subscribed', true)
                ->where('subscription_expires_at', '>', $maintenant)
                ->count(),
            'bientot' => User::where('is_subscribed', true)
                ->whereBetween('subscription_expires_at', [$maintenant, $maintenant->copy()->addDays(7)])
                ->count(),
            'revenus_mois' => (float) $revenusAbonnements()
                ->whereMonth('created_at', $maintenant->month)
                ->whereYear('created_at', $maintenant->year)
                ->sum('montant'),
            'revenus_total' => (float) $revenusAbonnements()->sum('montant'),
        ];
    }

    #[Computed]
    public function abonnes()
    {
        return User::query()
            ->where('is_subscribed', true)
            ->when(trim($this->recherche) !== '', function ($q) {
                $terme = '%' . trim($this->recherche) . '%';
                $q->where(function ($w) use ($terme) {
                    $w->where('name', 'like', $terme)
                        ->orWhere('email', 'like', $terme)
                        ->orWhere('phone', 'like', $terme);
                });
            })
            ->orderBy('subscription_expires_at')
            ->paginate(10);
    }

    #[Computed]
    public function paiements()
    {
        return Paiement::query()
            ->where('type', 'abonnement')
            ->with('user:id,name,email')
            ->when(in_array($this->statutPaiement, ['en_attente', 'reussi', 'echoue'], true),
                fn ($q) => $q->where('statut', $this->statutPaiement))
            ->when(trim($this->recherche) !== '', function ($q) {
                $terme = '%' . trim($this->recherche) . '%';
                $q->whereHas('user', function ($w) use ($terme) {
                    $w->where('name', 'like', $terme)->orWhere('email', 'like', $terme);
                });
            })
            ->latest()
            ->paginate(10);
    }
};
?>

@php
    $kpis = $this->kpis;
    $enPaiements = $onglet === 'paiements';
    $liste = $enPaiements ? $this->paiements : $this->abonnes;

    $fmt = fn ($n) => number_format((float) $n, 0, ',', ' ');
    $tarif = $fmt($this::TARIF_PREMIUM);

    $avantages = [
        'Publication de produits illimitée (2 produits maximum en gratuit)',
        'Profil boosté : vos produits apparaissent en premier dans le catalogue',
        'Paiement par Mobile Money, MTN ou Orange',
    ];

    $cartes = [
        ['label' => 'Abonnés actifs',        'valeur' => $fmt($kpis['actifs']),         'unite' => ''],
        ['label' => 'Expirent sous 7 jours', 'valeur' => $fmt($kpis['bientot']),        'unite' => ''],
        ['label' => 'Revenus du mois',       'valeur' => $fmt($kpis['revenus_mois']),   'unite' => 'FCFA'],
        ['label' => 'Revenus totaux',        'valeur' => $fmt($kpis['revenus_total']),  'unite' => 'FCFA'],
    ];

    // État d'un abonné à partir de sa date d'expiration
    $etatAbonne = function ($u) {
        if (! $u->subscription_expires_at) {
            return ['label' => 'Inconnu', 'classe' => 'bg-slate-100 text-slate-600', 'detail' => 'Date non renseignée', 'date' => '—'];
        }

        $exp = \Illuminate\Support\Carbon::parse($u->subscription_expires_at);
        $jours = (int) ceil(now()->diffInDays($exp, false));
        $date = $exp->format('d/m/Y');

        if ($exp->isPast()) {
            return ['label' => 'Expiré', 'classe' => 'bg-rose-50 text-rose-700', 'detail' => 'depuis ' . abs($jours) . ' j', 'date' => $date];
        }
        if ($jours <= 7) {
            return ['label' => 'Expire bientôt', 'classe' => 'bg-amber-50 text-amber-700', 'detail' => 'dans ' . max(1, $jours) . ' j', 'date' => $date];
        }

        return ['label' => 'Actif', 'classe' => 'bg-emerald-50 text-emerald-700', 'detail' => 'dans ' . $jours . ' j', 'date' => $date];
    };

    $statutsPaiement = [
        'en_attente' => ['label' => 'En attente', 'classe' => 'bg-amber-50 text-amber-700'],
        'reussi'     => ['label' => 'Réussi',     'classe' => 'bg-emerald-50 text-emerald-700'],
        'echoue'     => ['label' => 'Échoué',     'classe' => 'bg-rose-50 text-rose-700'],
    ];

    $libelleMethode = fn ($m) => match (strtolower((string) $m)) {
        'mtn' => 'MTN Mobile Money',
        'orange' => 'Orange Money',
        '' => '—',
        default => ucfirst((string) $m),
    };

    $filtresActifs = trim($recherche) !== '' || ($enPaiements && $statutPaiement !== 'tous');
    $ciblesChargement = 'onglet,recherche,statutPaiement,nextPage,previousPage,effacer';
@endphp

<div class="mx-auto max-w-7xl space-y-6">

    <div>
        <h2 class="text-2xl font-semibold tracking-tight text-slate-900">Abonnements</h2>
        <p class="mt-1 text-sm text-slate-500">Le forfait Premium des agriculteurs et les paiements qui l'activent.</p>
    </div>

    {{-- Forfait + chiffres --}}
    <section class="grid gap-4 lg:grid-cols-3">

        <div class="relative overflow-hidden rounded-2xl bg-emerald-900 p-6 text-white sm:p-7">
            <div class="pointer-events-none absolute -right-16 -top-16 h-56 w-56 rounded-full bg-emerald-800/60"></div>

            <div class="relative">
                <span class="inline-flex rounded-full bg-emerald-800 px-2.5 py-1 text-xs font-medium text-emerald-100">Forfait unique</span>
                <h3 class="mt-4 text-lg font-semibold">Premium</h3>

                <p class="mt-2 flex items-baseline gap-1.5">
                    <span class="text-4xl font-semibold tabular-nums tracking-tight">{{ $tarif }}</span>
                    <span class="text-sm text-emerald-200">FCFA / mois</span>
                </p>

                <ul class="mt-6 space-y-3">
                    @foreach ($avantages as $avantage)
                        <li class="flex items-start gap-2.5 text-sm text-emerald-50">
                            <svg class="mt-0.5 h-4 w-4 shrink-0 text-emerald-300" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5"><path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7"/></svg>
                            {{ $avantage }}
                        </li>
                    @endforeach
                </ul>

                <p class="mt-6 border-t border-emerald-800 pt-4 text-xs leading-relaxed text-emerald-200/80">
                    L'abonnement s'active automatiquement dès que le paiement Mobile Money est confirmé.
                </p>
            </div>
        </div>

        <div class="grid gap-4 sm:grid-cols-2 lg:col-span-2">
            @foreach ($cartes as $carte)
                <div class="rounded-2xl border border-slate-200/70 bg-white p-5 sm:p-6">
                    <p class="text-sm text-slate-500">{{ $carte['label'] }}</p>
                    <p class="mt-3 text-3xl font-semibold tabular-nums tracking-tight text-slate-900">
                        {{ $carte['valeur'] }}
                        @if ($carte['unite'])
                            <span class="text-sm font-medium text-slate-400">{{ $carte['unite'] }}</span>
                        @endif
                    </p>
                </div>
            @endforeach
        </div>
    </section>

    {{-- Abonnés / Paiements --}}
    <section class="rounded-2xl border border-slate-200/70 bg-white">

        <div class="space-y-4 border-b border-slate-100 p-4 sm:p-5">

            <div class="inline-flex rounded-xl bg-slate-100 p-1">
                @foreach (['abonnes' => 'Abonnés', 'paiements' => 'Paiements'] as $cle => $libelle)
                    <button type="button"
                            wire:click="$set('onglet', '{{ $cle }}')"
                            wire:loading.attr="disabled"
                            wire:target="onglet"
                            class="rounded-lg px-4 py-1.5 text-sm font-medium transition disabled:cursor-wait {{ $onglet === $cle ? 'bg-white text-emerald-800 shadow-sm' : 'text-slate-500 hover:text-slate-800' }}">
                        {{ $libelle }}
                    </button>
                @endforeach
            </div>

            <div class="flex flex-col gap-3 sm:flex-row">
                <div class="relative flex-1">
                    <svg class="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-4.35-4.35M17 10a7 7 0 11-14 0 7 7 0 0114 0z"/></svg>
                    <input type="search"
                           wire:model.live.debounce.400ms="recherche"
                           placeholder="Rechercher un agriculteur"
                           class="w-full rounded-xl border border-slate-200 bg-white py-2.5 pl-10 pr-10 text-sm text-slate-800 placeholder:text-slate-400 focus:border-emerald-500 focus:outline-none focus:ring-4 focus:ring-emerald-500/10">
                    <svg wire:loading wire:target="recherche" class="absolute right-3 top-1/2 h-4 w-4 -translate-y-1/2 animate-spin text-emerald-600 motion-reduce:animate-none" viewBox="0 0 24 24" fill="none"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"/><path class="opacity-90" fill="currentColor" d="M4 12a8 8 0 018-8v4a4 4 0 00-4 4H4z"/></svg>
                </div>

                @if ($enPaiements)
                    <select wire:model.live="statutPaiement"
                            aria-label="Filtrer par statut de paiement"
                            class="rounded-xl border border-slate-200 bg-white px-3 py-2.5 text-sm text-slate-700 focus:border-emerald-500 focus:outline-none focus:ring-4 focus:ring-emerald-500/10 sm:w-52">
                        <option value="tous">Tous les statuts</option>
                        <option value="reussi">Réussis</option>
                        <option value="en_attente">En attente</option>
                        <option value="echoue">Échoués</option>
                    </select>
                @endif
            </div>
        </div>

        <div class="relative">
            <div wire:loading.flex wire:target="{{ $ciblesChargement }}"
                 class="absolute inset-0 z-10 hidden items-start justify-center bg-white/60 pt-16 backdrop-blur-[1px]">
                <svg class="h-6 w-6 animate-spin text-emerald-600 motion-reduce:animate-none" viewBox="0 0 24 24" fill="none"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"/><path class="opacity-90" fill="currentColor" d="M4 12a8 8 0 018-8v4a4 4 0 00-4 4H4z"/></svg>
            </div>

            <div class="overflow-x-auto">
                @if (! $enPaiements)
                    {{-- ===== Abonnés ===== --}}
                    <table class="w-full min-w-[40rem] text-sm">
                        <thead>
                            <tr class="border-b border-slate-100 text-left text-xs font-medium text-slate-500">
                                <th class="px-5 py-3">Agriculteur</th>
                                <th class="hidden px-4 py-3 md:table-cell">Téléphone</th>
                                <th class="px-4 py-3">Expire le</th>
                                <th class="px-5 py-3">Statut</th>
                            </tr>
                        </thead>
                        <tbody class="divide-y divide-slate-100">
                            @forelse ($liste as $u)
                                @php
                                    $etat = $etatAbonne($u);
                                    $initiales = collect(preg_split('/\s+/', trim($u->name)))->filter()->take(2)
                                        ->map(fn ($p) => mb_strtoupper(mb_substr($p, 0, 1)))->implode('');
                                @endphp
                                <tr class="transition-colors hover:bg-slate-50/60" wire:key="abonne-{{ $u->id }}">
                                    <td class="px-5 py-3.5">
                                        <div class="flex items-center gap-3">
                                            <span class="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-emerald-100 text-xs font-semibold text-emerald-800">{{ $initiales }}</span>
                                            <div class="min-w-0">
                                                <p class="truncate font-medium text-slate-900">{{ $u->name }}</p>
                                                <p class="truncate text-xs text-slate-400">{{ $u->email }}</p>
                                            </div>
                                        </div>
                                    </td>
                                    <td class="hidden px-4 py-3.5 tabular-nums text-slate-600 md:table-cell">{{ $u->phone ?: '—' }}</td>
                                    <td class="px-4 py-3.5">
                                        <p class="tabular-nums text-slate-700">{{ $etat['date'] }}</p>
                                        <p class="text-xs text-slate-400">{{ $etat['detail'] }}</p>
                                    </td>
                                    <td class="px-5 py-3.5">
                                        <span class="inline-flex rounded-full px-2.5 py-1 text-xs font-medium {{ $etat['classe'] }}">{{ $etat['label'] }}</span>
                                    </td>
                                </tr>
                            @empty
                                <tr>
                                    <td colspan="4" class="px-5 py-16 text-center">
                                        <p class="text-sm font-medium text-slate-700">Aucun abonné Premium</p>
                                        <p class="mt-1 text-sm text-slate-400">
                                            {{ $filtresActifs ? 'Aucun résultat pour cette recherche.' : 'Les agriculteurs qui passent Premium apparaîtront ici.' }}
                                        </p>
                                        @if ($filtresActifs)
                                            <button type="button" wire:click="$set('recherche', '')" wire:loading.attr="disabled" wire:target="recherche"
                                                    class="mt-4 rounded-lg border border-slate-200 px-3 py-2 text-sm font-medium text-slate-600 transition hover:bg-slate-50 disabled:opacity-60">
                                                Effacer la recherche
                                            </button>
                                        @endif
                                    </td>
                                </tr>
                            @endforelse
                        </tbody>
                    </table>
                @else
                    {{-- ===== Paiements ===== --}}
                    <table class="w-full min-w-[48rem] text-sm">
                        <thead>
                            <tr class="border-b border-slate-100 text-left text-xs font-medium text-slate-500">
                                <th class="px-5 py-3">Agriculteur</th>
                                <th class="px-4 py-3">Montant</th>
                                <th class="hidden px-4 py-3 md:table-cell">Méthode</th>
                                <th class="hidden px-4 py-3 lg:table-cell">Durée</th>
                                <th class="hidden px-4 py-3 lg:table-cell">Référence</th>
                                <th class="px-4 py-3">Statut</th>
                                <th class="px-5 py-3 text-right">Date</th>
                            </tr>
                        </thead>
                        <tbody class="divide-y divide-slate-100">
                            @forelse ($liste as $p)
                                @php
                                    $statut = $statutsPaiement[$p->statut] ?? ['label' => ucfirst((string) $p->statut), 'classe' => 'bg-slate-100 text-slate-600'];
                                    $nomAgri = $p->user?->name ?? 'Compte supprimé';
                                @endphp
                                <tr class="transition-colors hover:bg-slate-50/60" wire:key="paiement-{{ $p->id }}">
                                    <td class="px-5 py-3.5">
                                        <p class="truncate font-medium text-slate-900">{{ $nomAgri }}</p>
                                        <p class="truncate text-xs text-slate-400">{{ $p->user?->email ?? '—' }}</p>
                                    </td>
                                    <td class="px-4 py-3.5 font-medium tabular-nums text-slate-900">{{ $fmt($p->montant) }} <span class="text-xs font-normal text-slate-400">FCFA</span></td>
                                    <td class="hidden px-4 py-3.5 text-slate-600 md:table-cell">{{ $libelleMethode($p->methode) }}</td>
                                    <td class="hidden px-4 py-3.5 text-slate-600 lg:table-cell">{{ $p->duree_mois ? $p->duree_mois . ' mois' : '—' }}</td>
                                    <td class="hidden px-4 py-3.5 font-mono text-xs text-slate-400 lg:table-cell">{{ $p->reference_api ? \Illuminate\Support\Str::limit($p->reference_api, 16) : '—' }}</td>
                                    <td class="px-4 py-3.5">
                                        <span class="inline-flex rounded-full px-2.5 py-1 text-xs font-medium {{ $statut['classe'] }}">{{ $statut['label'] }}</span>
                                    </td>
                                    <td class="px-5 py-3.5 text-right tabular-nums text-slate-500">{{ $p->created_at->format('d/m/Y H:i') }}</td>
                                </tr>
                            @empty
                                <tr>
                                    <td colspan="7" class="px-5 py-16 text-center">
                                        <p class="text-sm font-medium text-slate-700">Aucun paiement d'abonnement</p>
                                        <p class="mt-1 text-sm text-slate-400">
                                            {{ $filtresActifs ? 'Aucun résultat avec ces filtres.' : 'Les paiements apparaîtront ici dès la première souscription.' }}
                                        </p>
                                        @if ($filtresActifs)
                                            <button type="button" wire:click="$set('statutPaiement', 'tous')" x-on:click="$wire.recherche = ''"
                                                    class="mt-4 rounded-lg border border-slate-200 px-3 py-2 text-sm font-medium text-slate-600 transition hover:bg-slate-50">
                                                Effacer les filtres
                                            </button>
                                        @endif
                                    </td>
                                </tr>
                            @endforelse
                        </tbody>
                    </table>
                @endif
            </div>
        </div>

        @if ($liste->total() > 0)
            <div class="flex items-center justify-between gap-4 border-t border-slate-100 px-4 py-3 sm:px-5">
                <p class="text-sm text-slate-500">
                    <span class="tabular-nums">{{ $liste->firstItem() }}–{{ $liste->lastItem() }}</span>
                    sur <span class="tabular-nums">{{ $liste->total() }}</span>
                </p>
                <div class="flex gap-2">
                    <button type="button" wire:click="previousPage" wire:loading.attr="disabled" @disabled($liste->onFirstPage())
                            class="rounded-lg border border-slate-200 px-3 py-1.5 text-sm font-medium text-slate-600 transition hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-40">
                        Précédent
                    </button>
                    <button type="button" wire:click="nextPage" wire:loading.attr="disabled" @disabled(! $liste->hasMorePages())
                            class="rounded-lg border border-slate-200 px-3 py-1.5 text-sm font-medium text-slate-600 transition hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-40">
                        Suivant
                    </button>
                </div>
            </div>
        @endif
    </section>

</div>
