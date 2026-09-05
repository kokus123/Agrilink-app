<?php

use App\Models\Commande;
use App\Models\Paiement;
use App\Models\User;
use Livewire\Attributes\Layout;
use Livewire\Attributes\Title;
use Livewire\Component;

new
    #[Layout('components.layouts.admin')]
    #[Title('Tableau de bord')]
    class extends Component {

    public array $kpis = [];
    public array $revenusParMois = [];
    public $utilisateursRecents;

    public function mount(): void
    {
        $this->kpis = [
            'agriculteurs' => User::role('agriculteur')->count(),
            'acheteurs' => User::role('acheteur')->count(),
            'transporteurs' => User::role('transporteur')->count(),
            'abonnes_premium' => User::role('agriculteur')->abonnesPremium()->count(),
            'commandes_en_cours' => Commande::whereIn('statut', ['en_attente', 'confirmee', 'en_livraison'])->count(),
            'revenus_mois' => Paiement::reussis()
                ->whereMonth('created_at', now()->month)
                ->whereYear('created_at', now()->year)
                ->sum('montant'),
        ];

        // Revenus des 6 derniers mois pour le graphique
        $this->revenusParMois = collect(range(5, 0))->map(function ($i) {
            $mois = now()->subMonths($i);
            $total = Paiement::reussis()
                ->whereMonth('created_at', $mois->month)
                ->whereYear('created_at', $mois->year)
                ->sum('montant');

            return [
                'label' => $mois->translatedFormat('M Y'),
                'total' => (float) $total,
            ];
        })->toArray();

        $this->utilisateursRecents = User::latest()->take(5)->get();
    }
};
?>

<div class="space-y-6">

    {{-- Cartes KPI --}}
    <div class="grid grid-cols-2 lg:grid-cols-3 gap-4">

        <div class="bg-white rounded-lg shadow p-5">
            <div class="text-sm text-gray-500">Agriculteurs</div>
            <div class="text-2xl font-bold text-green-700">{{ $kpis['agriculteurs'] }}</div>
        </div>

        <div class="bg-white rounded-lg shadow p-5">
            <div class="text-sm text-gray-500">Acheteurs</div>
            <div class="text-2xl font-bold text-blue-700">{{ $kpis['acheteurs'] }}</div>
        </div>

        <div class="bg-white rounded-lg shadow p-5">
            <div class="text-sm text-gray-500">Transporteurs</div>
            <div class="text-2xl font-bold text-orange-600">{{ $kpis['transporteurs'] }}</div>
        </div>

        <div class="bg-white rounded-lg shadow p-5">
            <div class="text-sm text-gray-500">Abonnés Premium</div>
            <div class="text-2xl font-bold text-purple-700">{{ $kpis['abonnes_premium'] }}</div>
        </div>

        <div class="bg-white rounded-lg shadow p-5">
            <div class="text-sm text-gray-500">Commandes en cours</div>
            <div class="text-2xl font-bold text-yellow-600">{{ $kpis['commandes_en_cours'] }}</div>
        </div>

        <div class="bg-white rounded-lg shadow p-5">
            <div class="text-sm text-gray-500">Revenus ce mois</div>
            <div class="text-2xl font-bold text-green-800">{{ number_format($kpis['revenus_mois'], 0, ',', ' ') }} FCFA</div>
        </div>

    </div>

    {{-- Graphique des revenus --}}
    <div class="bg-white rounded-lg shadow p-5">
        <h2 class="text-sm font-semibold text-gray-600 mb-4">Revenus des 6 derniers mois</h2>
        <canvas id="revenusChart" height="90"></canvas>
    </div>

    {{-- Utilisateurs récents --}}
    <div class="bg-white rounded-lg shadow p-5 overflow-x-auto">
        <h2 class="text-sm font-semibold text-gray-600 mb-4">Derniers inscrits</h2>
        <table class="w-full text-sm">
            <thead>
                <tr class="text-left text-gray-500 border-b">
                    <th class="py-2 pr-4">Nom</th>
                    <th class="py-2 pr-4">Rôle</th>
                    <th class="py-2 pr-4">Statut</th>
                    <th class="py-2">Inscrit le</th>
                </tr>
            </thead>
            <tbody>
                @foreach($utilisateursRecents as $u)
                    <tr class="border-b last:border-0" wire:key="user-{{ $u->id }}">
                        <td class="py-2 pr-4">{{ $u->name }}</td>
                        <td class="py-2 pr-4 capitalize">{{ $u->role }}</td>
                        <td class="py-2 pr-4">
                            @if($u->is_active)
                                <span class="px-2 py-0.5 rounded-full bg-green-100 text-green-700 text-xs">Actif</span>
                            @else
                                <span class="px-2 py-0.5 rounded-full bg-red-100 text-red-700 text-xs">Bloqué</span>
                            @endif
                        </td>
                        <td class="py-2 text-gray-500">{{ $u->created_at->format('d/m/Y') }}</td>
                    </tr>
                @endforeach
            </tbody>
        </table>
    </div>

</div>

@script
<script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/4.4.0/chart.umd.min.js"></script>
<script>
    const ctx = document.getElementById('revenusChart');
    new Chart(ctx, {
        type: 'bar',
        data: {
            labels: @json(array_column($revenusParMois, 'label')),
            datasets: [{
                label: 'Revenus (FCFA)',
                data: @json(array_column($revenusParMois, 'total')),
                backgroundColor: '#15803d',
                borderRadius: 4,
            }]
        },
        options: {
            responsive: true,
            plugins: { legend: { display: false } },
            scales: { y: { beginAtZero: true } }
        }
    });
</script>
@endscript