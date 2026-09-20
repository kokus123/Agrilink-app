<?php

use App\Models\User;
use Illuminate\Database\QueryException;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Livewire\Attributes\Computed;
use Livewire\Attributes\Layout;
use Livewire\Attributes\Title;
use Livewire\Attributes\Url;
use Livewire\Component;
use Livewire\WithPagination;

new
    #[Layout('components.layouts.admin')]
    #[Title('Comptes utilisateurs')]
    class extends Component {
    use WithPagination;

    /* ---------- Filtres ---------- */

    #[Url(as: 'q', except: '')]
    public string $recherche = '';

    /** tous | agriculteur | acheteur | transporteur */
    #[Url(as: 'role', except: 'tous')]
    public string $role = 'tous';

    /** tous | actif | suspendu */
    #[Url(as: 'statut', except: 'tous')]
    public string $statut = 'tous';

    /* ---------- Formulaire « Créer un transporteur » ---------- */

    public string $nom = '';
    public string $email = '';
    public string $telephone = '';
    public string $motDePasse = '';

    public function updatedRecherche(): void
    {
        $this->resetPage();
    }

    public function updatedRole(): void
    {
        $this->resetPage();
    }

    public function updatedStatut(): void
    {
        $this->resetPage();
    }

    public function reinitialiserFiltres(): void
    {
        $this->reset(['recherche', 'role', 'statut']);
        $this->resetPage();
    }

    /* ---------- Validation ---------- */

    protected function rules(): array
    {
        return [
            'nom' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'max:255', 'unique:users,email'],
            'telephone' => ['required', 'string', 'max:20', 'unique:users,phone'],
            'motDePasse' => ['required', 'string', 'min:8', 'max:64'],
        ];
    }

    protected function messages(): array
    {
        return [
            'nom.required' => 'Le nom est obligatoire.',
            'nom.max' => 'Le nom est trop long.',
            'email.required' => "L'adresse e-mail est obligatoire.",
            'email.email' => "Cette adresse e-mail n'est pas valide.",
            'email.unique' => 'Un compte existe déjà avec cette adresse e-mail.',
            'telephone.required' => 'Le numéro de téléphone est obligatoire.',
            'telephone.unique' => 'Ce numéro de téléphone est déjà utilisé.',
            'telephone.max' => 'Le numéro de téléphone est trop long.',
            'motDePasse.required' => 'Le mot de passe est obligatoire.',
            'motDePasse.min' => 'Le mot de passe doit contenir au moins 8 caractères.',
        ];
    }

    /* ---------- Actions ---------- */

    public function genererMotDePasse(): void
    {
        $this->motDePasse = Str::password(12, symbols: false);
        $this->resetValidation('motDePasse');
    }

    public function reinitialiser(): void
    {
        $this->reset(['nom', 'email', 'telephone', 'motDePasse']);
        $this->resetValidation();
    }

    public function creer(): void
    {
        $this->validate();

        User::create([
            'name' => trim($this->nom),
            'email' => trim($this->email),
            'phone' => trim($this->telephone),
            'password' => Hash::make($this->motDePasse),
            'role' => 'transporteur',
            'is_active' => true,
            'is_subscribed' => false,
        ]);

        $this->reinitialiser();
        $this->resetPage();

        $this->dispatch('transporteur-cree');
        $this->dispatch('toast', type: 'success', message: 'Compte transporteur créé. Il peut se connecter avec son e-mail et le mot de passe choisi.');
    }

    public function toggleActif(int $id): void
    {
        $user = User::where('role', '!=', 'admin')->findOrFail($id);

        $user->is_active = ! $user->is_active;
        $user->save();

        // Un compte suspendu perd immédiatement l'accès à l'application mobile
        if (! $user->is_active) {
            $user->tokens()->delete();
        }

        $this->dispatch(
            'toast',
            type: 'success',
            message: $user->is_active
                ? "Le compte de {$user->name} est réactivé."
                : "Le compte de {$user->name} est suspendu."
        );
    }

    public function supprimer(int $id): void
    {
        $user = User::where('role', '!=', 'admin')->findOrFail($id);
        $nom = $user->name;
        $photo = $user->photo;

        try {
            DB::transaction(function () use ($user) {
                $user->tokens()->delete();
                $user->delete();
            });
        } catch (QueryException $e) {
            $this->dispatch(
                'toast',
                type: 'error',
                message: "Impossible de supprimer {$nom} : ce compte a des commandes, produits ou livraisons liés. Suspendez-le plutôt."
            );

            return;
        }

        if ($photo) {
            Storage::disk('public')->delete($photo);
        }

        // Si on vient de vider la dernière page, on revient en arrière
        unset($this->utilisateurs);
        if ($this->utilisateurs->isEmpty() && $this->getPage() > 1) {
            $this->previousPage();
        }

        $this->dispatch('toast', type: 'success', message: "Le compte de {$nom} a été supprimé.");
    }

    /* ---------- Données ---------- */

    #[Computed]
    public function utilisateurs()
    {
        $roles = ['agriculteur', 'acheteur', 'transporteur'];

        return User::query()
            ->where('role', '!=', 'admin')
            ->when(in_array($this->role, $roles, true), fn ($q) => $q->where('role', $this->role))
            ->when($this->statut === 'actif', fn ($q) => $q->where('is_active', true))
            ->when($this->statut === 'suspendu', fn ($q) => $q->where('is_active', false))
            ->when(trim($this->recherche) !== '', function ($q) {
                $terme = '%' . trim($this->recherche) . '%';
                $q->where(function ($w) use ($terme) {
                    $w->where('name', 'like', $terme)
                        ->orWhere('email', 'like', $terme)
                        ->orWhere('phone', 'like', $terme);
                });
            })
            ->latest()
            ->paginate(10);
    }

    #[Computed]
    public function compteurs(): array
    {
        $parRole = DB::table('users')
            ->where('role', '!=', 'admin')
            ->select('role', DB::raw('count(*) as total'))
            ->groupBy('role')
            ->pluck('total', 'role');

        return [
            'tous' => (int) $parRole->sum(),
            'agriculteur' => (int) ($parRole['agriculteur'] ?? 0),
            'acheteur' => (int) ($parRole['acheteur'] ?? 0),
            'transporteur' => (int) ($parRole['transporteur'] ?? 0),
        ];
    }
};
?>

@php
    $liste = $this->utilisateurs;
    $compteurs = $this->compteurs;

    $onglets = [
        'tous'         => 'Tous',
        'agriculteur'  => 'Agriculteurs',
        'acheteur'     => 'Acheteurs',
        'transporteur' => 'Transporteurs',
    ];

    $styleRoles = [
        'agriculteur'  => 'bg-emerald-50 text-emerald-700',
        'acheteur'     => 'bg-sky-50 text-sky-700',
        'transporteur' => 'bg-amber-50 text-amber-700',
    ];

    $filtresActifs = trim($recherche) !== '' || $role !== 'tous' || $statut !== 'tous';
    $ciblesChargement = 'recherche,role,statut,nextPage,previousPage,reinitialiserFiltres';
@endphp

<div class="mx-auto max-w-7xl space-y-6"
     x-data="{ ouvrir: false, voirMdp: false, suppr: null }"
     @transporteur-cree.window="ouvrir = false; voirMdp = false"
     @keydown.escape.window="ouvrir = false; suppr = null">

    {{-- En-tête --}}
    <div class="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
        <div>
            <h2 class="text-2xl font-semibold tracking-tight text-slate-900">Comptes utilisateurs</h2>
            <p class="mt-1 text-sm text-slate-500">
                Suivez les agriculteurs, acheteurs et transporteurs. Un compte suspendu ne peut plus se connecter à l'application.
            </p>
        </div>

        <button type="button" @click="ouvrir = true"
                class="inline-flex items-center justify-center gap-2 rounded-xl bg-emerald-700 px-4 py-2.5 text-sm font-semibold text-white shadow-sm shadow-emerald-900/10 transition hover:bg-emerald-800 focus:outline-none focus-visible:ring-4 focus-visible:ring-emerald-600/30">
            <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.2"><path stroke-linecap="round" stroke-linejoin="round" d="M12 5v14M5 12h14"/></svg>
            Créer un transporteur
        </button>
    </div>

    {{-- Liste --}}
    <section class="rounded-2xl border border-slate-200/70 bg-white">

        {{-- Filtres --}}
        <div class="space-y-4 border-b border-slate-100 p-4 sm:p-5">

            <div class="flex gap-1 overflow-x-auto rounded-xl bg-slate-100 p-1 sm:inline-flex">
                @foreach ($onglets as $cle => $libelle)
                    <button type="button"
                            wire:click="$set('role', '{{ $cle }}')"
                            wire:loading.attr="disabled"
                            wire:target="role"
                            class="flex shrink-0 items-center gap-2 rounded-lg px-3 py-1.5 text-sm font-medium transition disabled:cursor-wait {{ $role === $cle ? 'bg-white text-emerald-800 shadow-sm' : 'text-slate-500 hover:text-slate-800' }}">
                        {{ $libelle }}
                        <span class="rounded-full px-1.5 py-0.5 text-xs tabular-nums {{ $role === $cle ? 'bg-emerald-50 text-emerald-700' : 'bg-slate-200/70 text-slate-500' }}">{{ $compteurs[$cle] }}</span>
                    </button>
                @endforeach
            </div>

            <div class="flex flex-col gap-3 sm:flex-row">
                <div class="relative flex-1">
                    <svg class="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-4.35-4.35M17 10a7 7 0 11-14 0 7 7 0 0114 0z"/></svg>
                    <input type="search"
                           wire:model.live.debounce.400ms="recherche"
                           placeholder="Rechercher par nom, e-mail ou téléphone"
                           class="w-full rounded-xl border border-slate-200 bg-white py-2.5 pl-10 pr-10 text-sm text-slate-800 placeholder:text-slate-400 focus:border-emerald-500 focus:outline-none focus:ring-4 focus:ring-emerald-500/10">
                    <svg wire:loading wire:target="recherche" class="absolute right-3 top-1/2 h-4 w-4 -translate-y-1/2 animate-spin text-emerald-600 motion-reduce:animate-none" viewBox="0 0 24 24" fill="none"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"/><path class="opacity-90" fill="currentColor" d="M4 12a8 8 0 018-8v4a4 4 0 00-4 4H4z"/></svg>
                </div>

                <select wire:model.live="statut"
                        aria-label="Filtrer par statut"
                        class="rounded-xl border border-slate-200 bg-white px-3 py-2.5 text-sm text-slate-700 focus:border-emerald-500 focus:outline-none focus:ring-4 focus:ring-emerald-500/10 sm:w-48">
                    <option value="tous">Tous les statuts</option>
                    <option value="actif">Actifs</option>
                    <option value="suspendu">Suspendus</option>
                </select>
            </div>
        </div>

        {{-- Tableau --}}
        <div class="relative">
            <div wire:loading.flex wire:target="{{ $ciblesChargement }}"
                 class="absolute inset-0 z-10 hidden items-start justify-center bg-white/60 pt-16 backdrop-blur-[1px]">
                <svg class="h-6 w-6 animate-spin text-emerald-600 motion-reduce:animate-none" viewBox="0 0 24 24" fill="none"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"/><path class="opacity-90" fill="currentColor" d="M4 12a8 8 0 018-8v4a4 4 0 00-4 4H4z"/></svg>
            </div>

            <div class="overflow-x-auto">
                <table class="w-full min-w-[46rem] text-sm">
                    <thead>
                        <tr class="border-b border-slate-100 text-left text-xs font-medium text-slate-500">
                            <th class="px-5 py-3">Utilisateur</th>
                            <th class="px-4 py-3">Rôle</th>
                            <th class="hidden px-4 py-3 lg:table-cell">Téléphone</th>
                            <th class="px-4 py-3">Statut</th>
                            <th class="hidden px-4 py-3 md:table-cell">Inscrit le</th>
                            <th class="px-5 py-3 text-right">Actions</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-slate-100">
                        @forelse ($liste as $u)
                            @php
                                $initiales = collect(preg_split('/\s+/', trim($u->name)))
                                    ->filter()->take(2)
                                    ->map(fn ($p) => mb_strtoupper(mb_substr($p, 0, 1)))
                                    ->implode('');
                            @endphp
                            <tr class="transition-colors hover:bg-slate-50/60" wire:key="user-{{ $u->id }}">
                                <td class="px-5 py-3.5">
                                    <div class="flex items-center gap-3">
                                        <span class="flex h-9 w-9 shrink-0 items-center justify-center rounded-full text-xs font-semibold {{ $u->is_active ? 'bg-emerald-100 text-emerald-800' : 'bg-slate-100 text-slate-400' }}">{{ $initiales }}</span>
                                        <div class="min-w-0">
                                            <p class="truncate font-medium text-slate-900">{{ $u->name }}</p>
                                            <p class="truncate text-xs text-slate-400">{{ $u->email }}</p>
                                        </div>
                                    </div>
                                </td>

                                <td class="px-4 py-3.5">
                                    <div class="flex flex-wrap items-center gap-1.5">
                                        <span class="inline-flex rounded-full px-2.5 py-1 text-xs font-medium capitalize {{ $styleRoles[$u->role] ?? 'bg-slate-100 text-slate-600' }}">{{ $u->role }}</span>
                                        @if ($u->role === 'agriculteur' && $u->is_subscribed)
                                            <span class="inline-flex items-center gap-1 rounded-full bg-emerald-700 px-2 py-1 text-xs font-medium text-white">Premium</span>
                                        @endif
                                    </div>
                                </td>

                                <td class="hidden px-4 py-3.5 tabular-nums text-slate-600 lg:table-cell">{{ $u->phone ?: '—' }}</td>

                                <td class="px-4 py-3.5">
                                    <div class="flex items-center gap-3">
                                        <button type="button"
                                                wire:click="toggleActif({{ $u->id }})"
                                                wire:loading.attr="disabled"
                                                wire:target="toggleActif({{ $u->id }})"
                                                role="switch"
                                                aria-checked="{{ $u->is_active ? 'true' : 'false' }}"
                                                title="{{ $u->is_active ? 'Suspendre le compte' : 'Réactiver le compte' }}"
                                                class="relative inline-flex h-6 w-11 shrink-0 items-center rounded-full transition-colors focus:outline-none focus-visible:ring-4 focus-visible:ring-emerald-600/20 disabled:cursor-wait disabled:opacity-60 {{ $u->is_active ? 'bg-emerald-600' : 'bg-slate-300' }}">
                                            <span class="inline-block h-5 w-5 rounded-full bg-white shadow transition-transform {{ $u->is_active ? 'translate-x-[1.375rem]' : 'translate-x-0.5' }}"></span>
                                        </button>

                                        <span wire:loading.remove wire:target="toggleActif({{ $u->id }})"
                                              class="w-16 text-xs font-medium {{ $u->is_active ? 'text-emerald-700' : 'text-slate-400' }}">
                                            {{ $u->is_active ? 'Actif' : 'Suspendu' }}
                                        </span>
                                        <span wire:loading wire:target="toggleActif({{ $u->id }})" class="w-16">
                                            <svg class="h-4 w-4 animate-spin text-emerald-600 motion-reduce:animate-none" viewBox="0 0 24 24" fill="none"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"/><path class="opacity-90" fill="currentColor" d="M4 12a8 8 0 018-8v4a4 4 0 00-4 4H4z"/></svg>
                                        </span>
                                    </div>
                                </td>

                                <td class="hidden px-4 py-3.5 tabular-nums text-slate-500 md:table-cell">{{ $u->created_at->format('d/m/Y') }}</td>

                                <td class="px-5 py-3.5 text-right">
                                    <button type="button"
                                            data-nom="{{ $u->name }}"
                                            @click="suppr = { id: {{ $u->id }}, nom: $el.dataset.nom }"
                                            title="Supprimer ce compte"
                                            aria-label="Supprimer {{ $u->name }}"
                                            class="inline-flex h-9 w-9 items-center justify-center rounded-lg text-slate-400 transition hover:bg-rose-50 hover:text-rose-600 focus:outline-none focus-visible:ring-4 focus-visible:ring-rose-500/20">
                                        <svg class="h-[18px] w-[18px]" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8"><path stroke-linecap="round" stroke-linejoin="round" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/></svg>
                                    </button>
                                </td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="6" class="px-5 py-16 text-center">
                                    <p class="text-sm font-medium text-slate-700">Aucun utilisateur trouvé</p>
                                    <p class="mt-1 text-sm text-slate-400">
                                        {{ $filtresActifs ? 'Essayez de modifier ou d\'effacer les filtres.' : 'Les comptes apparaîtront ici dès la première inscription.' }}
                                    </p>
                                    @if ($filtresActifs)
                                        <button type="button" wire:click="reinitialiserFiltres" wire:loading.attr="disabled" wire:target="reinitialiserFiltres"
                                                class="mt-4 inline-flex items-center gap-2 rounded-lg border border-slate-200 px-3 py-2 text-sm font-medium text-slate-600 transition hover:bg-slate-50 disabled:opacity-60">
                                            Effacer les filtres
                                        </button>
                                    @endif
                                </td>
                            </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>

        {{-- Pagination --}}
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

    {{-- ===== Modale : créer un transporteur ===== --}}
    <div x-show="ouvrir" x-cloak class="fixed inset-0 z-50 flex items-end justify-center p-4 sm:items-center" role="dialog" aria-modal="true" aria-labelledby="titre-creation">
        <div x-show="ouvrir" x-transition.opacity @click="ouvrir = false; $wire.reinitialiser()" class="absolute inset-0 bg-emerald-950/40 backdrop-blur-sm"></div>

        <form wire:submit="creer"
              x-show="ouvrir"
              x-transition:enter="transition duration-200 ease-out"
              x-transition:enter-start="translate-y-4 opacity-0"
              x-transition:enter-end="translate-y-0 opacity-100"
              class="relative w-full max-w-md rounded-2xl bg-white p-6 shadow-xl">

            <h3 id="titre-creation" class="text-lg font-semibold text-slate-900">Créer un transporteur</h3>
            <p class="mt-1 text-sm text-slate-500">Le transporteur se connecte à l'application avec cet e-mail et ce mot de passe.</p>

            <div class="mt-5 space-y-4">
                <div>
                    <label for="nom" class="block text-sm font-medium text-slate-700">Nom complet</label>
                    <input id="nom" type="text" wire:model="nom" autocomplete="off"
                           class="mt-1.5 w-full rounded-xl border border-slate-200 px-3.5 py-2.5 text-sm focus:border-emerald-500 focus:outline-none focus:ring-4 focus:ring-emerald-500/10 @error('nom') border-rose-400 @enderror">
                    @error('nom') <p class="mt-1.5 text-xs text-rose-600">{{ $message }}</p> @enderror
                </div>

                <div>
                    <label for="email" class="block text-sm font-medium text-slate-700">Adresse e-mail</label>
                    <input id="email" type="email" wire:model="email" autocomplete="off"
                           class="mt-1.5 w-full rounded-xl border border-slate-200 px-3.5 py-2.5 text-sm focus:border-emerald-500 focus:outline-none focus:ring-4 focus:ring-emerald-500/10 @error('email') border-rose-400 @enderror">
                    @error('email') <p class="mt-1.5 text-xs text-rose-600">{{ $message }}</p> @enderror
                </div>

                <div>
                    <label for="telephone" class="block text-sm font-medium text-slate-700">Téléphone</label>
                    <input id="telephone" type="tel" wire:model="telephone" autocomplete="off" placeholder="6XX XXX XXX"
                           class="mt-1.5 w-full rounded-xl border border-slate-200 px-3.5 py-2.5 text-sm placeholder:text-slate-300 focus:border-emerald-500 focus:outline-none focus:ring-4 focus:ring-emerald-500/10 @error('telephone') border-rose-400 @enderror">
                    @error('telephone') <p class="mt-1.5 text-xs text-rose-600">{{ $message }}</p> @enderror
                </div>

                <div>
                    <div class="flex items-center justify-between">
                        <label for="motDePasse" class="block text-sm font-medium text-slate-700">Mot de passe</label>
                        <button type="button" wire:click="genererMotDePasse" @click="voirMdp = true" wire:loading.attr="disabled" wire:target="genererMotDePasse"
                                class="inline-flex items-center gap-1.5 text-xs font-medium text-emerald-700 hover:text-emerald-900 disabled:opacity-60">
                            <svg wire:loading wire:target="genererMotDePasse" class="h-3.5 w-3.5 animate-spin motion-reduce:animate-none" viewBox="0 0 24 24" fill="none"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"/><path class="opacity-90" fill="currentColor" d="M4 12a8 8 0 018-8v4a4 4 0 00-4 4H4z"/></svg>
                            Générer
                        </button>
                    </div>
                    <div class="relative mt-1.5">
                        <input id="motDePasse" wire:model="motDePasse" :type="voirMdp ? 'text' : 'password'" autocomplete="new-password"
                               class="w-full rounded-xl border border-slate-200 py-2.5 pl-3.5 pr-11 text-sm focus:border-emerald-500 focus:outline-none focus:ring-4 focus:ring-emerald-500/10 @error('motDePasse') border-rose-400 @enderror">
                        <button type="button" @click="voirMdp = ! voirMdp" class="absolute right-2 top-1/2 -translate-y-1/2 rounded-lg p-1.5 text-slate-400 hover:text-slate-600" :aria-label="voirMdp ? 'Masquer le mot de passe' : 'Afficher le mot de passe'">
                            <svg x-show="! voirMdp" class="h-[18px] w-[18px]" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8"><path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/></svg>
                            <svg x-show="voirMdp" x-cloak class="h-[18px] w-[18px]" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8"><path stroke-linecap="round" stroke-linejoin="round" d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l3.59 3.59m0 0A9.953 9.953 0 0112 5c4.478 0 8.268 2.943 9.543 7a10.025 10.025 0 01-4.132 5.411m0 0L21 21"/></svg>
                        </button>
                    </div>
                    @error('motDePasse') <p class="mt-1.5 text-xs text-rose-600">{{ $message }}</p> @enderror
                </div>
            </div>

            <div class="mt-6 flex flex-col-reverse gap-2 sm:flex-row sm:justify-end">
                <button type="button" @click="ouvrir = false" wire:click="reinitialiser"
                        class="rounded-xl border border-slate-200 px-4 py-2.5 text-sm font-medium text-slate-600 transition hover:bg-slate-50">
                    Annuler
                </button>
                <button type="submit" wire:loading.attr="disabled" wire:target="creer"
                        class="inline-flex items-center justify-center gap-2 rounded-xl bg-emerald-700 px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-emerald-800 focus:outline-none focus-visible:ring-4 focus-visible:ring-emerald-600/30 disabled:cursor-wait disabled:opacity-70">
                    <svg wire:loading wire:target="creer" class="h-4 w-4 animate-spin motion-reduce:animate-none" viewBox="0 0 24 24" fill="none"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"/><path class="opacity-90" fill="currentColor" d="M4 12a8 8 0 018-8v4a4 4 0 00-4 4H4z"/></svg>
                    <span wire:loading.remove wire:target="creer">Créer le compte</span>
                    <span wire:loading wire:target="creer">Création…</span>
                </button>
            </div>
        </form>
    </div>

    {{-- ===== Modale : confirmer la suppression ===== --}}
    <div x-show="suppr" x-cloak class="fixed inset-0 z-50 flex items-end justify-center p-4 sm:items-center" role="alertdialog" aria-modal="true" aria-labelledby="titre-suppression">
        <div x-show="suppr" x-transition.opacity @click="suppr = null" class="absolute inset-0 bg-emerald-950/40 backdrop-blur-sm"></div>

        <div x-show="suppr"
             x-transition:enter="transition duration-200 ease-out"
             x-transition:enter-start="translate-y-4 opacity-0"
             x-transition:enter-end="translate-y-0 opacity-100"
             class="relative w-full max-w-sm rounded-2xl bg-white p-6 shadow-xl">

            <span class="flex h-11 w-11 items-center justify-center rounded-full bg-rose-50 text-rose-600">
                <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8"><path stroke-linecap="round" stroke-linejoin="round" d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126zM12 15.75h.007v.008H12v-.008z"/></svg>
            </span>

            <h3 id="titre-suppression" class="mt-4 text-lg font-semibold text-slate-900">Supprimer ce compte ?</h3>
            <p class="mt-1.5 text-sm text-slate-500">
                Le compte de <span class="font-medium text-slate-800" x-text="suppr ? suppr.nom : ''"></span> sera supprimé définitivement. Cette action est irréversible.
                Pour bloquer simplement l'accès, suspendez-le à la place.
            </p>

            <div class="mt-6 flex flex-col-reverse gap-2 sm:flex-row sm:justify-end">
                <button type="button" @click="suppr = null"
                        class="rounded-xl border border-slate-200 px-4 py-2.5 text-sm font-medium text-slate-600 transition hover:bg-slate-50">
                    Annuler
                </button>
                <button type="button"
                        @click="$wire.supprimer(suppr.id).then(() => suppr = null)"
                        wire:loading.attr="disabled"
                        wire:target="supprimer"
                        class="inline-flex items-center justify-center gap-2 rounded-xl bg-rose-600 px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-rose-700 focus:outline-none focus-visible:ring-4 focus-visible:ring-rose-500/30 disabled:cursor-wait disabled:opacity-70">
                    <svg wire:loading wire:target="supprimer" class="h-4 w-4 animate-spin motion-reduce:animate-none" viewBox="0 0 24 24" fill="none"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"/><path class="opacity-90" fill="currentColor" d="M4 12a8 8 0 018-8v4a4 4 0 00-4 4H4z"/></svg>
                    <span wire:loading.remove wire:target="supprimer">Supprimer</span>
                    <span wire:loading wire:target="supprimer">Suppression…</span>
                </button>
            </div>
        </div>
    </div>

</div>
