<?php

namespace App\Observers;

use App\Jobs\SendDiscordWebhookNotification;
use App\Models\AuditLog;
use App\Models\DiscordWebhookSetting;

class AuditLogObserver
{
    public function created(AuditLog $auditLog): void
    {
        $settings = DiscordWebhookSetting::instance();

        if (! $settings->shouldNotify($auditLog->action)) {
            return;
        }

        SendDiscordWebhookNotification::dispatch(
            $settings->webhook_url,
            $auditLog->id,
        );
    }
}
