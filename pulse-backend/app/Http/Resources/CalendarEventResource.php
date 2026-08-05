<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class CalendarEventResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'title' => $this->title,
            'description' => $this->description,
            'start_at' => $this->start_at?->toIso8601String(),
            'end_at' => $this->end_at?->toIso8601String(),
            'is_meeting' => $this->is_meeting,
            'meeting_url' => $this->meeting_url,
            'linked_task' => $this->whenLoaded('linkedTask', fn () => $this->linkedTask ? [
                'id' => $this->linkedTask->id,
                'title' => $this->linkedTask->title,
            ] : null),
            'attendees' => $this->whenLoaded('attendees', fn () => $this->attendees->map(fn ($u) => [
                'id' => $u->id,
                'name' => $u->name,
                'avatar_url' => $u->avatar_url,
                'rsvp_status' => $u->pivot->rsvp_status,
            ])),
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}