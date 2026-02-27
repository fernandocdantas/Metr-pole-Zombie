<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Services\AuditLogger;
use App\Services\WhitelistManager;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Inertia\Inertia;
use Inertia\Response;

class WhitelistController extends Controller
{
    public function __construct(
        private readonly WhitelistManager $whitelistManager,
        private readonly AuditLogger $auditLogger,
    ) {}

    public function index(): Response
    {
        // Build a list of whitelisted usernames from PZ SQLite
        $whitelistedUsernames = [];

        try {
            $whitelistEntries = $this->whitelistManager->list();
            $whitelistedUsernames = array_column($whitelistEntries, 'username');
        } catch (\Throwable) {
            // SQLite not available
        }

        // Build character name lookup from players.db
        $characterNames = [];

        try {
            $networkPlayers = DB::connection('pz_players')
                ->table('networkPlayers')
                ->select('username', 'name')
                ->get();

            foreach ($networkPlayers as $player) {
                $characterNames[$player->username] = $player->name;
            }
        } catch (\Throwable) {
            // players.db not available
        }

        // Get all web users and enrich with whitelist status + character name
        $players = User::query()
            ->orderBy('username')
            ->get()
            ->map(fn (User $user) => [
                'username' => $user->username,
                'name' => $user->name,
                'character_name' => $characterNames[$user->username] ?? null,
                'whitelisted' => in_array($user->username, $whitelistedUsernames, true),
                'role' => $user->role->value,
            ])
            ->values()
            ->all();

        return Inertia::render('admin/whitelist', [
            'players' => $players,
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'username' => 'required|string|min:3|max:50',
            'password' => 'required|string|min:4|max:100',
        ]);

        $added = $this->whitelistManager->add($validated['username'], $validated['password']);

        if (! $added) {
            return response()->json(['error' => 'User already whitelisted'], 409);
        }

        $this->auditLogger->log(
            actor: $request->user()->name ?? 'admin',
            action: 'whitelist.add',
            target: $validated['username'],
            ip: $request->ip(),
        );

        return response()->json([
            'message' => 'User added to whitelist',
            'username' => $validated['username'],
        ], 201);
    }

    public function destroy(Request $request, string $username): JsonResponse
    {
        $removed = $this->whitelistManager->remove($username);

        if (! $removed) {
            return response()->json(['error' => 'User not found'], 404);
        }

        $this->auditLogger->log(
            actor: $request->user()->name ?? 'admin',
            action: 'whitelist.remove',
            target: $username,
            ip: $request->ip(),
        );

        return response()->json([
            'message' => 'User removed from whitelist',
            'username' => $username,
        ]);
    }

    public function toggle(Request $request, string $username): JsonResponse
    {
        $isWhitelisted = $this->whitelistManager->exists($username);

        if ($isWhitelisted) {
            $this->whitelistManager->remove($username);

            $this->auditLogger->log(
                actor: $request->user()->name ?? 'admin',
                action: 'whitelist.remove',
                target: $username,
                ip: $request->ip(),
            );

            return response()->json([
                'message' => 'User removed from whitelist',
                'whitelisted' => false,
            ]);
        }

        // Adding to whitelist requires a password
        $validated = $request->validate([
            'password' => 'required|string|min:4|max:100',
        ]);

        $this->whitelistManager->add($username, $validated['password']);

        $this->auditLogger->log(
            actor: $request->user()->name ?? 'admin',
            action: 'whitelist.add',
            target: $username,
            ip: $request->ip(),
        );

        return response()->json([
            'message' => 'User added to whitelist',
            'whitelisted' => true,
        ]);
    }

    public function sync(Request $request): JsonResponse
    {
        $result = $this->whitelistManager->syncWithPostgres();

        $this->auditLogger->log(
            actor: $request->user()->name ?? 'admin',
            action: 'whitelist.sync',
            details: $result,
            ip: $request->ip(),
        );

        return response()->json([
            'message' => 'Sync completed',
            'added' => $result['added'],
            'removed' => $result['removed'],
            'mismatches' => $result['mismatches'],
        ]);
    }
}
