<?php

namespace App\Services;

use App\Models\WhitelistEntry;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class WhitelistManager
{
    /**
     * List all whitelisted users from PZ's SQLite database.
     *
     * @return array<int, array{username: string, password_hash: string}>
     */
    public function list(): array
    {
        $rows = DB::connection('pz_sqlite')
            ->table('whitelist')
            ->select('username', 'password as password_hash')
            ->orderBy('username')
            ->get();

        return $rows->map(fn ($row) => [
            'username' => $row->username,
            'password_hash' => $row->password_hash,
        ])->all();
    }

    /**
     * Add a user to PZ's whitelist SQLite database.
     */
    public function add(string $username, string $password): bool
    {
        if ($this->exists($username)) {
            return false;
        }

        // PZ stores passwords as plain text in its SQLite DB
        DB::connection('pz_sqlite')
            ->table('whitelist')
            ->insert([
                'username' => $username,
                'password' => $password,
            ]);

        // Track in PostgreSQL
        WhitelistEntry::create([
            'pz_username' => $username,
            'pz_password_hash' => $password,
            'active' => true,
            'synced_at' => now(),
        ]);

        return true;
    }

    /**
     * Remove a user from PZ's whitelist SQLite database.
     */
    public function remove(string $username): bool
    {
        $deleted = DB::connection('pz_sqlite')
            ->table('whitelist')
            ->where('username', $username)
            ->delete();

        if ($deleted === 0) {
            return false;
        }

        // Mark inactive in PostgreSQL
        WhitelistEntry::where('pz_username', $username)
            ->update([
                'active' => false,
                'synced_at' => now(),
            ]);

        return true;
    }

    /**
     * Check if a user exists in PZ's whitelist.
     */
    public function exists(string $username): bool
    {
        return DB::connection('pz_sqlite')
            ->table('whitelist')
            ->where('username', $username)
            ->exists();
    }

    /**
     * Sync PostgreSQL whitelist_entries with PZ's SQLite state.
     *
     * @return array{added: string[], removed: string[], mismatches: int}
     */
    public function syncWithPostgres(): array
    {
        $sqliteUsers = collect($this->list())->pluck('username')->all();
        $pgEntries = WhitelistEntry::where('active', true)->pluck('pz_username')->all();

        $added = [];
        $removed = [];

        // Users in SQLite but not tracked in PG
        $inSqliteOnly = array_diff($sqliteUsers, $pgEntries);
        foreach ($inSqliteOnly as $username) {
            WhitelistEntry::create([
                'pz_username' => $username,
                'active' => true,
                'synced_at' => now(),
            ]);
            $added[] = $username;
        }

        // Users tracked as active in PG but not in SQLite
        $inPgOnly = array_diff($pgEntries, $sqliteUsers);
        foreach ($inPgOnly as $username) {
            WhitelistEntry::where('pz_username', $username)
                ->update(['active' => false, 'synced_at' => now()]);
            $removed[] = $username;
        }

        // Update sync timestamp for all matched entries
        WhitelistEntry::whereIn('pz_username', array_intersect($sqliteUsers, $pgEntries))
            ->update(['synced_at' => now()]);

        $mismatches = count($added) + count($removed);

        Log::info('Whitelist sync completed', [
            'added' => $added,
            'removed' => $removed,
            'mismatches' => $mismatches,
        ]);

        return [
            'added' => $added,
            'removed' => $removed,
            'mismatches' => $mismatches,
        ];
    }
}
