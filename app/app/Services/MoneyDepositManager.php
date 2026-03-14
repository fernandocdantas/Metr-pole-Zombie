<?php

namespace App\Services;

use App\Enums\TransactionSource;
use App\Models\WalletTransaction;
use App\Models\WhitelistEntry;
use Illuminate\Support\Str;

class MoneyDepositManager
{
    private string $requestsPath;

    private string $resultsPath;

    public function __construct(?string $requestsPath = null, ?string $resultsPath = null)
    {
        $this->requestsPath = $requestsPath ?? config('zomboid.lua_bridge.deposit_requests');
        $this->resultsPath = $resultsPath ?? config('zomboid.lua_bridge.deposit_results');
    }

    /**
     * Create a deposit request for a player.
     *
     * @return array{id: string, username: string, status: string, created_at: string}
     */
    public function createRequest(string $username): array
    {
        $data = $this->readJsonFile($this->requestsPath, ['version' => 1, 'updated_at' => '', 'requests' => []]);

        $entry = [
            'id' => Str::uuid()->toString(),
            'username' => $username,
            'status' => 'pending',
            'created_at' => date('c'),
        ];

        $data['requests'][] = $entry;
        $data['updated_at'] = date('c');

        $this->writeJsonFileAtomic($this->requestsPath, $data);

        return $entry;
    }

    /**
     * Check if a player has a pending (unprocessed) deposit request.
     */
    public function hasPendingRequest(string $username): bool
    {
        $data = $this->readJsonFile($this->requestsPath, ['version' => 1, 'updated_at' => '', 'requests' => []]);

        foreach ($data['requests'] as $request) {
            if ($request['username'] === $username && $request['status'] === 'pending') {
                return true;
            }
        }

        return false;
    }

    /**
     * Get the most recent deposit result for a user.
     *
     * @return array{id: string, username: string, status: string, money_count: int, stack_count: int, total_coins: int, message: string|null, processed_at: string}|null
     */
    public function getLastResult(string $username): ?array
    {
        $data = $this->readJsonFile($this->resultsPath, ['version' => 1, 'updated_at' => '', 'results' => []]);

        $last = null;
        foreach ($data['results'] as $result) {
            if ($result['username'] === $username) {
                $last = $result;
            }
        }

        return $last;
    }

    /**
     * Process deposit results: credit wallets and return count processed.
     */
    public function processResults(WalletService $walletService): int
    {
        $data = $this->readJsonFile($this->resultsPath, ['version' => 1, 'updated_at' => '', 'results' => []]);

        if (empty($data['results'])) {
            return 0;
        }

        $processed = 0;

        foreach ($data['results'] as $result) {
            if (($result['status'] ?? '') !== 'success') {
                continue;
            }

            // Dedup: skip if already credited
            if (WalletTransaction::query()->where('reference_id', $result['id'])->exists()) {
                continue;
            }

            $totalCoins = $result['total_coins'] ?? 0;
            if ($totalCoins <= 0) {
                continue;
            }

            // Look up user via WhitelistEntry
            $whitelistEntry = WhitelistEntry::query()
                ->where('pz_username', $result['username'])
                ->where('active', true)
                ->first();

            if (! $whitelistEntry || ! $whitelistEntry->user) {
                continue;
            }

            $wallet = $walletService->getOrCreateWallet($whitelistEntry->user);

            $walletService->credit(
                $wallet,
                (float) $totalCoins,
                TransactionSource::InGameDeposit,
                "In-game money deposit: {$result['money_count']}x Money + {$result['stack_count']}x MoneyStack",
                'deposit',
                $result['id'],
                [
                    'money_count' => $result['money_count'] ?? 0,
                    'stack_count' => $result['stack_count'] ?? 0,
                    'pz_username' => $result['username'],
                ],
            );

            $processed++;
        }

        return $processed;
    }

    /**
     * Remove stale pending requests older than 10 minutes.
     */
    public function cleanupStaleRequests(): void
    {
        $data = $this->readJsonFile($this->requestsPath, ['version' => 1, 'updated_at' => '', 'requests' => []]);
        $cutoff = strtotime('-10 minutes');
        $changed = false;

        $data['requests'] = array_values(array_filter($data['requests'], function ($request) use ($cutoff, &$changed) {
            $createdAt = strtotime($request['created_at'] ?? '');
            if ($request['status'] === 'pending' && $createdAt && $createdAt < $cutoff) {
                $changed = true;

                return false;
            }

            return true;
        }));

        if ($changed) {
            $data['updated_at'] = date('c');
            $this->writeJsonFileAtomic($this->requestsPath, $data);
        }
    }

    /**
     * Clear processed results from the results file.
     */
    public function cleanupResults(): bool
    {
        return $this->writeJsonFileAtomic($this->resultsPath, [
            'version' => 1,
            'updated_at' => date('c'),
            'results' => [],
        ]);
    }

    /**
     * Read and decode a JSON file, returning default on failure.
     */
    private function readJsonFile(string $path, array $default): array
    {
        if (! file_exists($path)) {
            return $default;
        }

        $content = file_get_contents($path);
        if ($content === false) {
            return $default;
        }

        $data = json_decode($content, true);
        if (json_last_error() !== JSON_ERROR_NONE) {
            return $default;
        }

        return $data;
    }

    /**
     * Write JSON data atomically using temp file + rename.
     */
    private function writeJsonFileAtomic(string $path, array $data): bool
    {
        $dir = dirname($path);
        if (! is_dir($dir)) {
            mkdir($dir, 0755, true);
        }

        $tmpPath = $path.'.tmp.'.getmypid();
        $json = json_encode($data, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);

        if (file_put_contents($tmpPath, $json) === false) {
            return false;
        }

        return rename($tmpPath, $path);
    }
}
