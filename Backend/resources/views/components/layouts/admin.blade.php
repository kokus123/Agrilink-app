<!DOCTYPE html>
<html lang="fr" class="h-full">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ $title ?? 'Admin' }} - AGRILINK</title>

    {{-- Applique l'état de la sidebar AVANT l'affichage (évite le clignotement) --}}
    <script>
        try {
            if (localStorage.getItem('agrilink-sidebar') === 'reduit') {
                document.documentElement.classList.add('sidebar-reduit');
            }
        } catch (e) {}
    </script>

    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Geist:wght@400;500;600;700&display=swap" rel="stylesheet">

    <style>
        [x-cloak] { display: none !important; }

        body {
            font-family: 'Geist', ui-sans-serif, system-ui, -apple-system, 'Segoe UI', sans-serif;
            font-feature-settings: 'ss01', 'cv11';
        }

        .app-sidebar { transition: width .2s ease, transform .2s ease; }
        .app-content { transition: padding-left .2s ease; }

        /* Sidebar réduite (bureau uniquement) : seules les icônes restent visibles */
        @media (min-width: 1024px) {
            .sidebar-reduit .app-sidebar { width: 4.5rem; }
            .sidebar-reduit .app-content { padding-left: 4.5rem; }
            .sidebar-reduit .sidebar-label { display: none; }
            .sidebar-reduit .sidebar-item,
            .sidebar-reduit .sidebar-logo,
            .sidebar-reduit .sidebar-profil { justify-content: center; padding-left: 0; padding-right: 0; }
        }

        @media (prefers-reduced-motion: reduce) {
            .app-sidebar, .app-content { transition: none; }
        }

        /* Barre de progression Livewire (navigation entre pages) aux couleurs Agrilink */
        #nprogress .bar { background: #059669 !important; height: 3px !important; }
        #nprogress .peg { box-shadow: 0 0 10px #059669, 0 0 5px #059669 !important; }
        #nprogress .spinner { display: none !important; }
    </style>

    @vite(['resources/css/app.css', 'resources/js/app.js'])
    @livewireStyles
</head>
<body class="min-h-full bg-[#f6f8f7] text-slate-800 antialiased"
      x-data="{
          sidebarOpen: false,
          deconnexion: false,
          reduire() {
              const reduit = document.documentElement.classList.toggle('sidebar-reduit');
              try { localStorage.setItem('agrilink-sidebar', reduit ? 'reduit' : 'ouvert'); } catch (e) {}
          }
      }"
      @keydown.escape.window="deconnexion = false">

    @php
        $nav = [
            [
                'route' => 'admin.dashboard',
                'label' => 'Tableau de bord',
                'icon'  => 'M4 5a1 1 0 011-1h4a1 1 0 011 1v5a1 1 0 01-1 1H5a1 1 0 01-1-1V5zm10 0a1 1 0 011-1h4a1 1 0 011 1v2a1 1 0 01-1 1h-4a1 1 0 01-1-1V5zM4 15a1 1 0 011-1h4a1 1 0 011 1v4a1 1 0 01-1 1H5a1 1 0 01-1-1v-4zm10-3a1 1 0 011-1h4a1 1 0 011 1v7a1 1 0 01-1 1h-4a1 1 0 01-1-1v-7z',
            ],
            [
                'route' => 'admin.utilisateurs',
                'label' => 'Comptes utilisateurs',
                'icon'  => 'M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z',
            ],
            [
                'route' => 'admin.abonnements',
                'label' => 'Abonnements',
                'icon'  => 'M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z',
            ],
            [
                'route' => 'admin.statistiques',
                'label' => 'Statistiques',
                'icon'  => 'M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z',
            ],
        ];

        $adminName = auth()->user()->name;
        $adminInitiales = collect(preg_split('/\s+/', trim($adminName)))
            ->filter()
            ->take(2)
            ->map(fn ($p) => mb_strtoupper(mb_substr($p, 0, 1)))
            ->implode('');
    @endphp

    {{-- Overlay mobile --}}
    <div x-show="sidebarOpen"
         x-cloak
         x-transition.opacity
         @click="sidebarOpen = false"
         class="fixed inset-0 z-30 bg-emerald-950/40 backdrop-blur-sm lg:hidden"></div>

    {{-- Sidebar FIXE : ne bouge jamais, seul le contenu défile --}}
    <aside
        class="app-sidebar fixed inset-y-0 left-0 z-40 flex w-64 flex-col border-r border-slate-200/70 bg-white lg:translate-x-0"
        :class="sidebarOpen ? 'translate-x-0' : '-translate-x-full'"
    >
        {{-- Logo --}}
        <div class="flex h-16 shrink-0 items-center justify-between px-5 sidebar-logo">
            <a href="{{ route('admin.dashboard') }}" wire:navigate class="flex items-center gap-2.5" title="Agrilink">
                <span class="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-emerald-700 text-base">🌾</span>
                <span class="sidebar-label text-[17px] font-semibold tracking-tight text-slate-900">Agrilink</span>
            </a>
            <button @click="sidebarOpen = false" class="sidebar-label rounded-lg p-1.5 text-slate-400 hover:bg-slate-100 hover:text-slate-600 lg:hidden" aria-label="Fermer le menu">
                <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"/></svg>
            </button>
        </div>

        {{-- Navigation (défile toute seule si trop longue) --}}
        <nav class="flex-1 space-y-0.5 overflow-y-auto px-3 py-2">
            @foreach ($nav as $item)
                @php $actif = request()->routeIs($item['route']); @endphp
                <a href="{{ route($item['route']) }}"
                   wire:navigate
                   title="{{ $item['label'] }}"
                   @click="sidebarOpen = false"
                   @if ($actif) aria-current="page" @endif
                   @class([
                       'sidebar-item group flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-colors',
                       'bg-emerald-50 text-emerald-800' => $actif,
                       'text-slate-500 hover:bg-slate-50 hover:text-slate-900' => ! $actif,
                   ])>
                    <svg @class([
                            'h-5 w-5 shrink-0',
                            'text-emerald-600' => $actif,
                            'text-slate-400 group-hover:text-slate-600' => ! $actif,
                        ]) fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                        <path stroke-linecap="round" stroke-linejoin="round" d="{{ $item['icon'] }}"/>
                    </svg>
                    <span class="sidebar-label">{{ $item['label'] }}</span>
                </a>
            @endforeach
        </nav>

        {{-- Profil + déconnexion --}}
        <div class="shrink-0 border-t border-slate-100 p-3">
            <div class="sidebar-profil flex items-center gap-3 px-2 py-2" title="{{ $adminName }}">
                <span class="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-emerald-100 text-xs font-semibold text-emerald-800">{{ $adminInitiales }}</span>
                <div class="sidebar-label min-w-0 flex-1">
                    <p class="truncate text-sm font-medium text-slate-800">{{ $adminName }}</p>
                    <p class="truncate text-xs text-slate-400">Administrateur</p>
                </div>
            </div>

            <button type="button"
                    @click="deconnexion = true; sidebarOpen = false"
                    title="Se déconnecter"
                    class="sidebar-item mt-1 flex w-full items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium text-slate-500 transition-colors hover:bg-rose-50 hover:text-rose-600">
                <svg class="h-5 w-5 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8"><path stroke-linecap="round" stroke-linejoin="round" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"/></svg>
                <span class="sidebar-label">Se déconnecter</span>
            </button>
        </div>
    </aside>

    {{-- Zone de contenu : décalée de la largeur de la sidebar, c'est elle qui défile --}}
    <div class="app-content min-h-screen lg:pl-64">

        <header class="sticky top-0 z-20 flex h-16 items-center gap-3 border-b border-slate-200/70 bg-white/80 px-4 backdrop-blur-md sm:px-6 lg:px-8">
            {{-- Mobile : ouvre le menu --}}
            <button @click="sidebarOpen = true" class="-ml-1 rounded-lg p-2 text-slate-500 hover:bg-slate-100 lg:hidden" aria-label="Ouvrir le menu">
                <svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M4 6h16M4 12h16M4 18h16"/></svg>
            </button>

            {{-- Bureau : réduit / agrandit le menu --}}
            <button @click="reduire()" class="-ml-1 hidden rounded-lg p-2 text-slate-500 transition hover:bg-slate-100 hover:text-slate-800 lg:inline-flex" aria-label="Réduire ou agrandir le menu" title="Réduire / agrandir le menu">
                <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8"><path stroke-linecap="round" stroke-linejoin="round" d="M4 6a2 2 0 012-2h12a2 2 0 012 2v12a2 2 0 01-2 2H6a2 2 0 01-2-2V6zm5-2v16"/></svg>
            </button>

            <h1 class="text-base font-semibold tracking-tight text-slate-900">{{ $title ?? 'Tableau de bord' }}</h1>

            <span class="ml-auto flex h-8 w-8 items-center justify-center rounded-full bg-emerald-700 text-xs font-semibold text-white">{{ $adminInitiales }}</span>
        </header>

        <main class="p-4 sm:p-6 lg:p-8">
            {{ $slot }}
        </main>
    </div>

    {{-- Alerte de confirmation : déconnexion --}}
    <div x-show="deconnexion" x-cloak class="fixed inset-0 z-50 flex items-end justify-center p-4 sm:items-center" role="alertdialog" aria-modal="true" aria-labelledby="titre-deconnexion">
        <div x-show="deconnexion" x-transition.opacity @click="deconnexion = false" class="absolute inset-0 bg-emerald-950/40 backdrop-blur-sm"></div>

        <form method="POST" action="{{ route('logout') }}"
              x-show="deconnexion"
              x-data="{ loading: false }"
              @submit="loading = true"
              @pageshow.window="loading = false"
              x-transition:enter="transition duration-200 ease-out"
              x-transition:enter-start="translate-y-4 opacity-0"
              x-transition:enter-end="translate-y-0 opacity-100"
              class="relative w-full max-w-sm rounded-2xl bg-white p-6 shadow-xl">
            @csrf

            <span class="flex h-11 w-11 items-center justify-center rounded-full bg-rose-50 text-rose-600">
                <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8"><path stroke-linecap="round" stroke-linejoin="round" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"/></svg>
            </span>

            <h3 id="titre-deconnexion" class="mt-4 text-lg font-semibold text-slate-900">Se déconnecter ?</h3>
            <p class="mt-1.5 text-sm text-slate-500">
                Vous allez quitter l'espace administration. Vous devrez vous reconnecter pour y accéder de nouveau.
            </p>

            <div class="mt-6 flex flex-col-reverse gap-2 sm:flex-row sm:justify-end">
                <button type="button" @click="deconnexion = false" :disabled="loading"
                        class="rounded-xl border border-slate-200 px-4 py-2.5 text-sm font-medium text-slate-600 transition hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-50">
                    Annuler
                </button>
                <button type="submit" :disabled="loading"
                        class="inline-flex items-center justify-center gap-2 rounded-xl bg-rose-600 px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-rose-700 focus:outline-none focus-visible:ring-4 focus-visible:ring-rose-500/30 disabled:cursor-wait disabled:opacity-70">
                    <svg x-show="loading" x-cloak class="h-4 w-4 animate-spin motion-reduce:animate-none" viewBox="0 0 24 24" fill="none"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"/><path class="opacity-90" fill="currentColor" d="M4 12a8 8 0 018-8v4a4 4 0 00-4 4H4z"/></svg>
                    <span x-text="loading ? 'Déconnexion…' : 'Se déconnecter'">Se déconnecter</span>
                </button>
            </div>
        </form>
    </div>

    {{-- Notifications (toasts) : $this->dispatch('toast', type: 'success', message: '...') --}}
    <div x-data="{
            toasts: [],
            ajouter(d) {
                const id = Date.now() + Math.random();
                this.toasts.push({ id: id, type: d.type || 'success', message: d.message || '' });
                setTimeout(() => { this.toasts = this.toasts.filter(t => t.id !== id); }, 4500);
            }
         }"
         @toast.window="ajouter($event.detail)"
         class="pointer-events-none fixed inset-x-4 bottom-4 z-[60] flex flex-col items-end gap-2 sm:inset-x-auto sm:bottom-6 sm:right-6">
        <template x-for="t in toasts" :key="t.id">
            <div class="pointer-events-auto flex w-full items-start gap-3 rounded-xl border bg-white p-4 shadow-lg sm:w-96"
                 :class="t.type === 'error' ? 'border-rose-200' : 'border-emerald-200'"
                 role="status">
                <span class="mt-0.5 flex h-5 w-5 shrink-0 items-center justify-center rounded-full text-white"
                      :class="t.type === 'error' ? 'bg-rose-500' : 'bg-emerald-600'">
                    <svg x-show="t.type !== 'error'" class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="3"><path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7"/></svg>
                    <svg x-show="t.type === 'error'" x-cloak class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="3"><path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"/></svg>
                </span>
                <p class="flex-1 text-sm text-slate-700" x-text="t.message"></p>
                <button type="button" @click="toasts = toasts.filter(x => x.id !== t.id)" class="text-slate-400 hover:text-slate-600" aria-label="Fermer">
                    <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"/></svg>
                </button>
            </div>
        </template>
    </div>

    @livewireScripts
</body>
</html>