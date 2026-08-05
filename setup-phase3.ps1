# Pulse Backend - Phase 3 file setup script
# Run this from inside your pulse-backend folder:
#   powershell -ExecutionPolicy Bypass -File setup-phase3.ps1

Write-Host "Creating Phase 3 files..." -ForegroundColor Cyan

New-Item -ItemType Directory -Force -Path "app\Http\Requests" | Out-Null
New-Item -ItemType Directory -Force -Path "app\Http\Resources" | Out-Null
New-Item -ItemType Directory -Force -Path "app\Services" | Out-Null

Set-Content -Path "database\migrations\2024_01_03_000001_create_notes_table.php" -Encoding UTF8 -Value @'
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('notes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('workspace_id')->constrained()->cascadeOnDelete();
            $table->foreignId('created_by')->constrained('users')->cascadeOnDelete();
            $table->string('title', 255);
            $table->longText('content_markdown')->nullable();
            $table->boolean('is_pinned')->default(false);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('notes');
    }
};
'@

Set-Content -Path "app\Models\Note.php" -Encoding UTF8 -Value @'
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Note extends Model
{
    protected $fillable = [
        'workspace_id',
        'created_by',
        'title',
        'content_markdown',
        'is_pinned',
    ];

    protected function casts(): array
    {
        return [
            'is_pinned' => 'boolean',
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
}
'@

Set-Content -Path "app\Http\Requests\StoreNoteRequest.php" -Encoding UTF8 -Value @'
<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreNoteRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'title' => ['required', 'string', 'max:255'],
            'content_markdown' => ['nullable', 'string'],
            'is_pinned' => ['nullable', 'boolean'],
        ];
    }
}
'@

Set-Content -Path "app\Http\Requests\UpdateNoteRequest.php" -Encoding UTF8 -Value @'
<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateNoteRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'title' => ['sometimes', 'string', 'max:255'],
            'content_markdown' => ['nullable', 'string'],
            'is_pinned' => ['nullable', 'boolean'],
        ];
    }
}
'@

Set-Content -Path "app\Http\Requests\AiNoteActionRequest.php" -Encoding UTF8 -Value @'
<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class AiNoteActionRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            // The raw markdown content (or selected excerpt) to act on.
            'content' => ['required', 'string', 'max:20000'],
            // Only used by the rewrite endpoint. Ignored elsewhere.
            'tone' => ['nullable', 'string', 'in:concise,formal,friendly,confident'],
        ];
    }
}
'@

Set-Content -Path "app\Http\Resources\NoteResource.php" -Encoding UTF8 -Value @'
<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class NoteResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'title' => $this->title,
            'content_markdown' => $this->content_markdown,
            'is_pinned' => $this->is_pinned,
            'creator' => $this->whenLoaded('creator', fn () => [
                'id' => $this->creator->id,
                'name' => $this->creator->name,
            ]),
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
'@

Set-Content -Path "app\Http\Controllers\Api\V1\NoteController.php" -Encoding UTF8 -Value @'
<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreNoteRequest;
use App\Http\Requests\UpdateNoteRequest;
use App\Http\Resources\NoteResource;
use App\Models\Note;
use Illuminate\Http\Request;

class NoteController extends Controller
{
    /**
     * GET /api/v1/notes
     * Filters: q (search title), pinned (1/0)
     */
    public function index(Request $request)
    {
        $workspaceId = $request->attributes->get('workspace_id');

        $query = Note::query()
            ->where('workspace_id', $workspaceId)
            ->with('creator');

        $query->when($request->filled('q'), fn ($q) => $q->where('title', 'like', '%' . $request->q . '%'));
        $query->when($request->filled('pinned'), fn ($q) => $q->where('is_pinned', $request->boolean('pinned')));

        $notes = $query->orderByDesc('is_pinned')->orderByDesc('updated_at')->paginate($request->integer('per_page', 20));

        return response()->json([
            'data' => NoteResource::collection($notes->items()),
            'meta' => [
                'page' => $notes->currentPage(),
                'per_page' => $notes->perPage(),
                'total' => $notes->total(),
            ],
            'error' => null,
        ]);
    }

    /**
     * POST /api/v1/notes
     */
    public function store(StoreNoteRequest $request)
    {
        $workspaceId = $request->attributes->get('workspace_id');

        $note = Note::create([
            'workspace_id' => $workspaceId,
            'created_by' => $request->user()->id,
            'title' => $request->title,
            'content_markdown' => $request->content_markdown,
            'is_pinned' => $request->boolean('is_pinned'),
        ]);

        $note->load('creator');

        return response()->json([
            'data' => new NoteResource($note),
            'meta' => null,
            'error' => null,
        ], 201);
    }

    /**
     * GET /api/v1/notes/{note}
     */
    public function show(Request $request, Note $note)
    {
        $this->authorizeWorkspace($request, $note);
        $note->load('creator');

        return response()->json([
            'data' => new NoteResource($note),
            'meta' => null,
            'error' => null,
        ]);
    }

    /**
     * PATCH /api/v1/notes/{note}
     */
    public function update(UpdateNoteRequest $request, Note $note)
    {
        $this->authorizeWorkspace($request, $note);

        $note->fill($request->only(['title', 'content_markdown', 'is_pinned']));
        $note->save();

        $note->load('creator');

        return response()->json([
            'data' => new NoteResource($note),
            'meta' => null,
            'error' => null,
        ]);
    }

    /**
     * DELETE /api/v1/notes/{note}
     */
    public function destroy(Request $request, Note $note)
    {
        $this->authorizeWorkspace($request, $note);
        $note->delete();

        return response()->json([
            'data' => ['message' => 'Note deleted.'],
            'meta' => null,
            'error' => null,
        ]);
    }

    private function authorizeWorkspace(Request $request, Note $note): void
    {
        abort_unless(
            $note->workspace_id === $request->attributes->get('workspace_id'),
            404
        );
    }
}
'@

Set-Content -Path "app\Http\Controllers\Api\V1\AiController.php" -Encoding UTF8 -Value @'
<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\AiNoteActionRequest;
use App\Http\Requests\AiSuggestTaskRequest;
use App\Models\AiUsageLog;
use App\Models\Category;
use App\Services\AiService;
use Illuminate\Support\Facades\DB;

class AiController extends Controller
{
    public function __construct(private AiService $aiService)
    {
    }

    /**
     * POST /api/v1/ai/tasks/suggest
     */
    public function suggestTask(AiSuggestTaskRequest $request)
    {
        $workspaceId = $request->attributes->get('workspace_id');

        $existingCategories = Category::where('workspace_id', $workspaceId)
            ->get(['id', 'name'])
            ->toArray();

        $result = $this->aiService->suggestTask($request->prompt, $existingCategories);

        $this->logUsage($request, $workspaceId, 'task_suggest', $result['tokens_used']);

        return response()->json([
            'data' => $result['suggestion'],
            'meta' => null,
            'error' => null,
        ]);
    }

    /**
     * POST /api/v1/ai/notes/summarize
     */
    public function summarizeNote(AiNoteActionRequest $request)
    {
        $workspaceId = $request->attributes->get('workspace_id');

        $result = $this->aiService->summarizeNote($request->content);

        $this->logUsage($request, $workspaceId, 'note_summarize', $result['tokens_used']);

        return response()->json([
            'data' => [
                'summary' => $result['summary'],
                'key_points' => $result['key_points'],
            ],
            'meta' => null,
            'error' => null,
        ]);
    }

    /**
     * POST /api/v1/ai/notes/rewrite
     */
    public function rewriteNote(AiNoteActionRequest $request)
    {
        $workspaceId = $request->attributes->get('workspace_id');

        $result = $this->aiService->rewriteNote($request->content, $request->input('tone', 'concise'));

        $this->logUsage($request, $workspaceId, 'note_rewrite', $result['tokens_used']);

        return response()->json([
            'data' => ['rewritten' => $result['rewritten']],
            'meta' => null,
            'error' => null,
        ]);
    }

    /**
     * POST /api/v1/ai/notes/grammar-fix
     */
    public function fixGrammar(AiNoteActionRequest $request)
    {
        $workspaceId = $request->attributes->get('workspace_id');

        $result = $this->aiService->fixGrammar($request->content);

        $this->logUsage($request, $workspaceId, 'grammar_fix', $result['tokens_used']);

        return response()->json([
            'data' => ['corrected' => $result['corrected']],
            'meta' => null,
            'error' => null,
        ]);
    }

    private function logUsage($request, int $workspaceId, string $feature, int $tokensUsed): void
    {
        DB::transaction(function () use ($request, $workspaceId, $feature, $tokensUsed) {
            AiUsageLog::create([
                'workspace_id' => $workspaceId,
                'user_id' => $request->user()->id,
                'feature' => $feature,
                'tokens_used' => $tokensUsed,
            ]);
        });
    }
}
'@

Set-Content -Path "app\Services\AiService.php" -Encoding UTF8 -Value @'
<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class AiService
{
    private string $apiKey;
    private string $model;

    public function __construct()
    {
        $this->apiKey = config('services.ai.api_key', '');
        $this->model = config('services.ai.model', 'claude-sonnet-4-6');
    }

    /**
     * Turns a rough task title/context into a structured suggestion:
     * refined title, category guess, priority, due date guess, subtasks.
     *
     * Returns ['suggestion' => array, 'tokens_used' => int]
     */
    public function suggestTask(string $roughPrompt, array $existingCategories = []): array
    {
        $categoryList = collect($existingCategories)->pluck('name')->implode(', ') ?: 'none yet';

        $systemPrompt = <<<PROMPT
        You are a productivity assistant inside a task manager. Given a rough,
        unstructured task description from the user, respond with ONLY a JSON
        object (no prose, no markdown fences) with this exact shape:

        {
          "title": "refined, clear task title (max 80 chars)",
          "category_suggestion": "one of: {$categoryList}, or a new short category name",
          "priority": "low | medium | high | urgent",
          "due_date_suggestion": "YYYY-MM-DD or null if no clear deadline implied",
          "subtasks": ["short subtask 1", "short subtask 2"]
        }

        Keep subtasks to at most 3 items. If the input is too vague to infer
        a due date, use null. Never include explanations outside the JSON.
        PROMPT;

        if (empty($this->apiKey)) {
            return [
                'suggestion' => [
                    'title' => ucfirst($roughPrompt),
                    'category_suggestion' => $existingCategories[0]['name'] ?? 'General',
                    'priority' => 'medium',
                    'due_date_suggestion' => null,
                    'subtasks' => [],
                ],
                'tokens_used' => 0,
            ];
        }

        $result = $this->callClaudeForJson($systemPrompt, $roughPrompt, 400);

        return [
            'suggestion' => $result['data'],
            'tokens_used' => $result['tokens_used'],
        ];
    }

    /**
     * Summarizes note content into a short paragraph + bullet key points.
     * Returns ['summary' => string, 'key_points' => string[], 'tokens_used' => int]
     */
    public function summarizeNote(string $content): array
    {
        $systemPrompt = <<<PROMPT
        You summarize notes for a productivity app. Respond with ONLY a JSON
        object (no prose, no markdown fences) with this exact shape:

        {
          "summary": "2-3 sentence plain-language summary",
          "key_points": ["short key point 1", "short key point 2", "short key point 3"]
        }

        Keep key_points to at most 5 items. Never include explanations outside the JSON.
        PROMPT;

        if (empty($this->apiKey)) {
            return [
                'summary' => \Illuminate\Support\Str::limit(strip_tags($content), 160),
                'key_points' => [],
                'tokens_used' => 0,
            ];
        }

        $result = $this->callClaudeForJson($systemPrompt, $content, 400);

        return [
            'summary' => $result['data']['summary'] ?? '',
            'key_points' => $result['data']['key_points'] ?? [],
            'tokens_used' => $result['tokens_used'],
        ];
    }

    /**
     * Rewrites note content in a requested tone.
     * Returns ['rewritten' => string, 'tokens_used' => int]
     */
    public function rewriteNote(string $content, string $tone = 'concise'): array
    {
        $systemPrompt = <<<PROMPT
        You rewrite text for a productivity app in a {$tone} tone. Preserve
        the original meaning and markdown formatting. Respond with ONLY the
        rewritten markdown text -- no preamble, no explanations, no code fences.
        PROMPT;

        if (empty($this->apiKey)) {
            return [
                'rewritten' => $content,
                'tokens_used' => 0,
            ];
        }

        $result = $this->callClaudeForText($systemPrompt, $content, 800);

        return [
            'rewritten' => $result['text'],
            'tokens_used' => $result['tokens_used'],
        ];
    }

    /**
     * Fixes grammar/spelling while preserving voice and formatting.
     * Returns ['corrected' => string, 'tokens_used' => int]
     */
    public function fixGrammar(string $content): array
    {
        $systemPrompt = <<<PROMPT
        You correct grammar and spelling only. Do not change the meaning,
        tone, or markdown formatting. Respond with ONLY the corrected
        markdown text -- no preamble, no explanations, no code fences.
        PROMPT;

        if (empty($this->apiKey)) {
            return [
                'corrected' => $content,
                'tokens_used' => 0,
            ];
        }

        $result = $this->callClaudeForText($systemPrompt, $content, 800);

        return [
            'corrected' => $result['text'],
            'tokens_used' => $result['tokens_used'],
        ];
    }

    /**
     * Calls Claude expecting a JSON object back. Strips markdown fences
     * defensively in case the model wraps the JSON despite instructions.
     */
    private function callClaudeForJson(string $systemPrompt, string $userContent, int $maxTokens): array
    {
        $raw = $this->callClaude($systemPrompt, $userContent, $maxTokens);
        $clean = trim(preg_replace('/```json|```/', '', $raw['text']));

        return [
            'data' => json_decode($clean, true) ?? [],
            'tokens_used' => $raw['tokens_used'],
        ];
    }

    private function callClaudeForText(string $systemPrompt, string $userContent, int $maxTokens): array
    {
        return $this->callClaude($systemPrompt, $userContent, $maxTokens);
    }

    /**
     * Low-level call to the Anthropic Messages API.
     * Returns ['text' => string, 'tokens_used' => int]
     */
    private function callClaude(string $systemPrompt, string $userContent, int $maxTokens): array
    {
        $response = Http::withHeaders([
            'x-api-key' => $this->apiKey,
            'anthropic-version' => '2023-06-01',
            'content-type' => 'application/json',
        ])->post('https://api.anthropic.com/v1/messages', [
            'model' => $this->model,
            'max_tokens' => $maxTokens,
            'system' => $systemPrompt,
            'messages' => [
                ['role' => 'user', 'content' => $userContent],
            ],
        ]);

        if ($response->failed()) {
            Log::error('AI call failed', ['body' => $response->body()]);
            throw new \RuntimeException('AI request failed. Please try again.');
        }

        $data = $response->json();
        $text = collect($data['content'] ?? [])
            ->firstWhere('type', 'text')['text'] ?? '';

        $tokensUsed = ($data['usage']['input_tokens'] ?? 0) + ($data['usage']['output_tokens'] ?? 0);

        return ['text' => $text, 'tokens_used' => $tokensUsed];
    }
}
'@

Set-Content -Path "routes\api.php" -Encoding UTF8 -Value @'
<?php

use App\Http\Controllers\Api\V1\AiController;
use App\Http\Controllers\Api\V1\AuthController;
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

            Route::prefix('ai')->group(function () {
                Route::post('tasks/suggest', [AiController::class, 'suggestTask']);
                Route::post('notes/summarize', [AiController::class, 'summarizeNote']);
                Route::post('notes/rewrite', [AiController::class, 'rewriteNote']);
                Route::post('notes/grammar-fix', [AiController::class, 'fixGrammar']);
            });

            // Route::apiResource('calendar/events', CalendarEventController::class); // Phase 4
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

Write-Host "All Phase 3 files created/overwritten successfully!" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  php artisan config:clear"
Write-Host "  php artisan migrate"
Write-Host "  (restart php artisan serve)"
