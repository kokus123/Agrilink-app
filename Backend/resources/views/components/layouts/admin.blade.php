<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ $title ?? 'Admin' }} - AGRILINK</title>
    @vite(['resources/css/app.css', 'resources/js/app.js'])
    @livewireStyles
</head>
<body class="bg-gray-100 text-gray-900" x-data="{ sidebarOpen: false }">
    <div class="flex min-h-screen">

        {{-- Overlay mobile (visible seulement quand la sidebar est ouverte) --}}
        <div x-show="sidebarOpen"
             x-cloak
             @click="sidebarOpen = false"
             class="fixed inset-0 bg-black/50 z-30 lg:hidden"></div>

        {{-- Sidebar : cachée par défaut sur mobile (translate-x -full), toujours visible sur lg+ --}}
        <aside
            class="fixed inset-y-0 left-0 z-40 w-64 bg-green-800 text-white flex flex-col
                   transform transition-transform duration-200 ease-in-out
                   -translate-x-full lg:translate-x-0 lg:static"
            :class="sidebarOpen ? 'translate-x-0' : '-translate-x-full'"
        >
            <div class="px-6 py-5 flex items-center justify-between border-b border-green-700">
                <span class="text-xl font-bold">🌾 AGRILINK <span class="text-sm font-normal opacity-75">Admin</span></span>
                <button @click="sidebarOpen = false" class="lg:hidden text-white text-2xl leading-none">&times;</button>
            </div>

            <nav class="flex-1 px-3 py-4 space-y-1">
                <a href="{{ route('admin.dashboard') }}"
                   class="block px-3 py-2 rounded-md hover:bg-green-700 {{ request()->routeIs('admin.dashboard') ? 'bg-green-700' : '' }}">
                    Tableau de bord
                </a>
                <a href="{{ route('admin.utilisateurs') }}"
                   class="block px-3 py-2 rounded-md hover:bg-green-700 {{ request()->routeIs('admin.utilisateurs') ? 'bg-green-700' : '' }}">
                    Comptes utilisateurs
                </a>
                <a href="{{ route('admin.abonnements') }}"
                   class="block px-3 py-2 rounded-md hover:bg-green-700 {{ request()->routeIs('admin.abonnements') ? 'bg-green-700' : '' }}">
                    Abonnements
                </a>
                <a href="{{ route('admin.statistiques') }}"
                   class="block px-3 py-2 rounded-md hover:bg-green-700 {{ request()->routeIs('admin.statistiques') ? 'bg-green-700' : '' }}">
                    Statistiques
                </a>
            </nav>

            <div class="px-3 py-4 border-t border-green-700">
                <div class="text-sm opacity-80 px-3 truncate">{{ auth()->user()->name }}</div>
                <form method="POST" action="{{ route('logout') }}">
                    @csrf
                    <button type="submit" class="mt-2 w-full text-left px-3 py-2 rounded-md hover:bg-green-700 text-sm">
                        Déconnexion
                    </button>
                </form>
            </div>
        </aside>

        {{-- Contenu principal --}}
        <div class="flex-1 flex flex-col min-w-0">
            <header class="bg-white shadow px-4 py-4 flex items-center gap-3">
                {{-- Bouton hamburger, visible seulement sur mobile/tablette --}}
                <button @click="sidebarOpen = true" class="lg:hidden text-gray-600">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
                    </svg>
                </button>
                <h1 class="text-lg font-semibold">{{ $title ?? 'Tableau de bord' }}</h1>
            </header>

            <main class="flex-1 p-4 lg:p-6">
                {{ $slot }}
            </main>
        </div>
    </div>

    @livewireScripts
</body>
</html>