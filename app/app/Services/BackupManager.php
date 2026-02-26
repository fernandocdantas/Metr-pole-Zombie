<?php

namespace App\Services;

use App\Enums\BackupType;
use App\Models\Backup;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Process;

class BackupManager
{
    public function __construct(
        private readonly RconClient $rcon,
    ) {}

    /**
     * Create a backup of PZ save data + config files.
     *
     * @return array{backup: Backup, cleanup_count: int}
     */
    public function createBackup(BackupType $type, ?string $notes = null): array
    {
        $this->triggerServerSave();

        $backupDir = config('zomboid.backups.path');
        $this->ensureDirectoryExists($backupDir);

        $timestamp = now()->format('Y-m-d_H-i-s');
        $filename = "backup_{$type->value}_{$timestamp}.tar.gz";
        $fullPath = rtrim($backupDir, '/').'/'.$filename;

        $this->createTarGz($fullPath);

        $sizeBytes = file_exists($fullPath) ? filesize($fullPath) : 0;

        $backup = Backup::create([
            'filename' => $filename,
            'path' => $fullPath,
            'size_bytes' => $sizeBytes,
            'type' => $type,
            'notes' => $notes,
        ]);

        $cleanupCount = $this->cleanupRetention($type);

        return [
            'backup' => $backup,
            'cleanup_count' => $cleanupCount,
        ];
    }

    /**
     * Delete a backup file and its database record.
     */
    public function deleteBackup(Backup $backup): bool
    {
        if (file_exists($backup->path)) {
            @unlink($backup->path);
        }

        return $backup->delete();
    }

    /**
     * Enforce retention policy for a backup type.
     */
    public function cleanupRetention(BackupType $type): int
    {
        $keep = config("zomboid.backups.retention.{$type->value}", 10);

        $backups = Backup::where('type', $type->value)
            ->orderByDesc('created_at')
            ->get();

        if ($backups->count() <= $keep) {
            return 0;
        }

        $toDelete = $backups->slice($keep);
        $deleted = 0;

        foreach ($toDelete as $backup) {
            if (file_exists($backup->path)) {
                @unlink($backup->path);
            }
            $backup->delete();
            $deleted++;
        }

        return $deleted;
    }

    /**
     * Trigger RCON save before backup. Non-fatal if server is offline.
     */
    private function triggerServerSave(): void
    {
        try {
            $this->rcon->connect();
            $this->rcon->command('save');
            sleep(3);
        } catch (\Throwable $e) {
            Log::info('RCON save skipped during backup — server may be offline', [
                'error' => $e->getMessage(),
            ]);
        }
    }

    /**
     * Create a tar.gz archive of PZ data directory contents.
     */
    private function createTarGz(string $outputPath): void
    {
        $dataPath = config('zomboid.paths.data');

        if (! is_dir($dataPath)) {
            throw new \RuntimeException("PZ data directory not found: {$dataPath}");
        }

        $result = Process::run([
            'tar', '-czf', $outputPath,
            '-C', $dataPath,
            'Server', 'Saves', 'db',
        ]);

        if (! $result->successful()) {
            // Partial backup is acceptable — some dirs may not exist yet
            Log::warning('Backup tar command had warnings', [
                'output' => $result->output(),
                'error' => $result->errorOutput(),
                'exit_code' => $result->exitCode(),
            ]);
        }
    }

    private function ensureDirectoryExists(string $path): void
    {
        if (! is_dir($path)) {
            mkdir($path, 0755, true);
        }
    }
}
