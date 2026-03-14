<?php

namespace App\Console\Commands;

use App\Services\MoneyDepositManager;
use App\Services\WalletService;
use Illuminate\Console\Command;

class ProcessMoneyDeposits extends Command
{
    protected $signature = 'zomboid:process-money-deposits';

    protected $description = 'Process in-game money deposit results and credit wallets';

    public function handle(MoneyDepositManager $depositManager, WalletService $walletService): int
    {
        // Clean up stale requests first
        $depositManager->cleanupStaleRequests();

        // Process results and credit wallets
        $count = $depositManager->processResults($walletService);

        if ($count > 0) {
            $this->info("Credited {$count} money deposit(s) to wallets.");

            // Clear processed results
            $depositManager->cleanupResults();
        }

        return self::SUCCESS;
    }
}
