<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreCalendarEventRequest;
use App\Http\Requests\UpdateCalendarEventRequest;
use App\Http\Resources\CalendarEventResource;
use App\Models\CalendarEvent;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class CalendarEventController extends Controller
{
    /**
     * GET /api/v1/calendar/events
     * Query params: from, to (ISO date/datetime) -- required for a sane
     * calendar view; without a range this could return unbounded rows.
     */
    public function index(Request $request)
    {
        $workspaceId = $request->attributes->get('workspace_id');

        $query = CalendarEvent::query()
            ->where('workspace_id', $workspaceId)
            ->with(['linkedTask', 'attendees']);

        $query->when($request->filled('from'), fn ($q) => $q->where('end_at', '>=', $request->from));
        $query->when($request->filled('to'), fn ($q) => $q->where('start_at', '<=', $request->to));

        $events = $query->orderBy('start_at')->get();

        return response()->json([
            'data' => CalendarEventResource::collection($events),
            'meta' => ['total' => $events->count()],
            'error' => null,
        ]);
    }

    /**
     * POST /api/v1/calendar/events
     */
    public function store(StoreCalendarEventRequest $request)
    {
        $workspaceId = $request->attributes->get('workspace_id');

        $event = DB::transaction(function () use ($request, $workspaceId) {
            $event = CalendarEvent::create([
                'workspace_id' => $workspaceId,
                'created_by' => $request->user()->id,
                'linked_task_id' => $request->linked_task_id,
                'title' => $request->title,
                'description' => $request->description,
                'start_at' => $request->start_at,
                'end_at' => $request->end_at,
                'is_meeting' => $request->boolean('is_meeting'),
                'meeting_url' => $request->meeting_url,
            ]);

            if ($request->filled('attendee_ids')) {
                $event->attendees()->sync(
                    collect($request->attendee_ids)->mapWithKeys(fn ($id) => [$id => ['rsvp_status' => 'pending']])
                );
            }

            return $event;
        });

        $event->load(['linkedTask', 'attendees']);

        return response()->json([
            'data' => new CalendarEventResource($event),
            'meta' => null,
            'error' => null,
        ], 201);
    }

    /**
     * GET /api/v1/calendar/events/{event}
     */
    public function show(Request $request, CalendarEvent $event)
    {
        $this->authorizeWorkspace($request, $event);
        $event->load(['linkedTask', 'attendees']);

        return response()->json([
            'data' => new CalendarEventResource($event),
            'meta' => null,
            'error' => null,
        ]);
    }

    /**
     * PATCH /api/v1/calendar/events/{event}
     * Also used for drag-and-drop reschedule (start_at/end_at only).
     */
    public function update(UpdateCalendarEventRequest $request, CalendarEvent $event)
    {
        $this->authorizeWorkspace($request, $event);

        $event->fill($request->only([
            'title', 'description', 'start_at', 'end_at',
            'is_meeting', 'meeting_url', 'linked_task_id',
        ]));
        $event->save();

        if ($request->has('attendee_ids')) {
            $event->attendees()->sync(
                collect($request->attendee_ids)->mapWithKeys(fn ($id) => [$id => ['rsvp_status' => 'pending']])
            );
        }

        $event->load(['linkedTask', 'attendees']);

        return response()->json([
            'data' => new CalendarEventResource($event),
            'meta' => null,
            'error' => null,
        ]);
    }

    /**
     * DELETE /api/v1/calendar/events/{event}
     */
    public function destroy(Request $request, CalendarEvent $event)
    {
        $this->authorizeWorkspace($request, $event);
        $event->delete();

        return response()->json([
            'data' => ['message' => 'Event deleted.'],
            'meta' => null,
            'error' => null,
        ]);
    }

    private function authorizeWorkspace(Request $request, CalendarEvent $event): void
    {
        abort_unless(
            $event->workspace_id === $request->attributes->get('workspace_id'),
            404
        );
    }
}