# Pulse Backend - Phase 4 file setup script (BOM-safe)
# Run from inside your pulse-backend folder:
#   powershell -ExecutionPolicy Bypass -File setup-phase4.ps1

Write-Host "Creating Phase 4 (Calendar) files..." -ForegroundColor Cyan

New-Item -ItemType Directory -Force -Path "app\Http\Requests" | Out-Null
New-Item -ItemType Directory -Force -Path "app\Http\Resources" | Out-Null

$enc = New-Object System.Text.UTF8Encoding $false

$c0 = @'
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('calendar_events', function (Blueprint $table) {
            $table->id();
            $table->foreignId('workspace_id')->constrained()->cascadeOnDelete();
            $table->foreignId('created_by')->constrained('users')->cascadeOnDelete();
            $table->foreignId('linked_task_id')->nullable()->constrained('tasks')->nullOnDelete();
            $table->string('title', 255);
            $table->text('description')->nullable();
            $table->dateTime('start_at');
            $table->dateTime('end_at');
            $table->boolean('is_meeting')->default(false);
            $table->string('meeting_url')->nullable();
            $table->timestamps();

            $table->index(['workspace_id', 'start_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('calendar_events');
    }
};
'@
[System.IO.File]::WriteAllText("database\migrations\2024_01_04_000001_create_calendar_events_table.php", $c0, $enc)
Write-Host "  Created: database\migrations\2024_01_04_000001_create_calendar_events_table.php"

$c1 = @'
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('event_attendees', function (Blueprint $table) {
            $table->foreignId('event_id')->constrained('calendar_events')->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->enum('rsvp_status', ['pending', 'accepted', 'declined'])->default('pending');
            $table->primary(['event_id', 'user_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('event_attendees');
    }
};
'@
[System.IO.File]::WriteAllText("database\migrations\2024_01_04_000002_create_event_attendees_table.php", $c1, $enc)
Write-Host "  Created: database\migrations\2024_01_04_000002_create_event_attendees_table.php"

$c2 = @'
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CalendarEvent extends Model
{
    protected $fillable = [
        'workspace_id',
        'created_by',
        'linked_task_id',
        'title',
        'description',
        'start_at',
        'end_at',
        'is_meeting',
        'meeting_url',
    ];

    protected function casts(): array
    {
        return [
            'start_at' => 'datetime',
            'end_at' => 'datetime',
            'is_meeting' => 'boolean',
        ];
    }

    public function workspace()
    {
        return $this->belongsTo(Workspace::class);
    }

    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function linkedTask()
    {
        return $this->belongsTo(Task::class, 'linked_task_id');
    }

    public function attendees()
    {
        return $this->belongsToMany(User::class, 'event_attendees', 'event_id', 'user_id')
            ->withPivot('rsvp_status');
    }
}
'@
[System.IO.File]::WriteAllText("app\Models\CalendarEvent.php", $c2, $enc)
Write-Host "  Created: app\Models\CalendarEvent.php"

$c3 = @'
<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreCalendarEventRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'title' => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'start_at' => ['required', 'date'],
            'end_at' => ['required', 'date', 'after:start_at'],
            'is_meeting' => ['nullable', 'boolean'],
            'meeting_url' => ['nullable', 'url', 'max:255'],
            'linked_task_id' => ['nullable', 'integer', 'exists:tasks,id'],
            'attendee_ids' => ['nullable', 'array'],
            'attendee_ids.*' => ['integer', 'exists:users,id'],
        ];
    }
}
'@
[System.IO.File]::WriteAllText("app\Http\Requests\StoreCalendarEventRequest.php", $c3, $enc)
Write-Host "  Created: app\Http\Requests\StoreCalendarEventRequest.php"

$c4 = @'
<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateCalendarEventRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'title' => ['sometimes', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'start_at' => ['sometimes', 'date'],
            'end_at' => ['sometimes', 'date', 'after:start_at'],
            'is_meeting' => ['nullable', 'boolean'],
            'meeting_url' => ['nullable', 'url', 'max:255'],
            'linked_task_id' => ['nullable', 'integer', 'exists:tasks,id'],
            'attendee_ids' => ['nullable', 'array'],
            'attendee_ids.*' => ['integer', 'exists:users,id'],
        ];
    }
}
'@
[System.IO.File]::WriteAllText("app\Http\Requests\UpdateCalendarEventRequest.php", $c4, $enc)
Write-Host "  Created: app\Http\Requests\UpdateCalendarEventRequest.php"

$c5 = @'
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
'@
[System.IO.File]::WriteAllText("app\Http\Resources\CalendarEventResource.php", $c5, $enc)
Write-Host "  Created: app\Http\Resources\CalendarEventResource.php"

$c6 = @'
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
'@
[System.IO.File]::WriteAllText("app\Http\Controllers\Api\V1\CalendarEventController.php", $c6, $enc)
Write-Host "  Created: app\Http\Controllers\Api\V1\CalendarEventController.php"

$c7 = @'
<?php

use App\Http\Controllers\Api\V1\AiController;
use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\CalendarEventController;
use App\Http\Controllers\Api\V1\NoteController;
use App\Http\Controllers\Api\V1\TaskController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {

    // Public auth routes
    Route::prefix('auth')->group(function () {
        Route::post('register', [AuthController::class, 'register']);
        Route::post('login', [AuthController::class, 'login']);
        Route::post('refresh', [AuthController::class, 'refresh'])->middleware('auth:api');
        Route::post('logout', [AuthController::class, 'logout'])->middleware('auth:api');
    });

    // Authenticated routes
    Route::middleware('auth:api')->group(function () {
        Route::get('me', [AuthController::class, 'me']);

        // Workspace-scoped routes (require X-Workspace-Id header)
        Route::middleware('ensure.workspace.member')->group(function () {
            Route::apiResource('tasks', TaskController::class);
            Route::apiResource('notes', NoteController::class);
            Route::apiResource('calendar/events', CalendarEventController::class)
                ->parameters(['events' => 'event']);

            Route::prefix('ai')->group(function () {
                Route::post('tasks/suggest', [AiController::class, 'suggestTask']);
                Route::post('notes/summarize', [AiController::class, 'summarizeNote']);
                Route::post('notes/rewrite', [AiController::class, 'rewriteNote']);
                Route::post('notes/grammar-fix', [AiController::class, 'fixGrammar']);
            });
        });

        // Admin routes
        Route::prefix('admin')
            ->middleware(['ensure.workspace.member', 'ensure.admin'])
            ->group(function () {
                // Route::get('overview', [AdminOverviewController::class, 'index']);
            });
    });
});
'@
[System.IO.File]::WriteAllText("routes\api.php", $c7, $enc)
Write-Host "  Created: routes\api.php"

Write-Host "All Phase 4 files created." -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  php artisan config:clear"
Write-Host "  php artisan migrate"
Write-Host "  (restart php artisan serve)"
