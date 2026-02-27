<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class GameEvent extends Model
{
    protected $fillable = [
        'event_type',
        'player',
        'target',
        'details',
        'game_time',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'details' => 'array',
            'game_time' => 'datetime',
        ];
    }
}
