# Pulse Backend - Phase 5 file setup script (Team/Workspace members, BOM-safe)
# Run from inside your pulse-backend folder:
#   powershell -ExecutionPolicy Bypass -File setup-phase5.ps1

Write-Host "Creating Phase 5 (Team) files..." -ForegroundColor Cyan

New-Item -ItemType Directory -Force -Path "app\Http\Requests" | Out-Null
New-Item -ItemType Directory -Force -Path "app\Http\Resources" | Out-Null

$enc = New-Object System.Text.UTF8Encoding $false

$c0 = @'
<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class InviteMemberRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // gated by ensure.admin middleware on the route
    }

    public function rules(): array
    {
        return [
            'email' => ['required', 'email', 'max:190'],
            'role' => ['required', 'in:admin,member,viewer'], // owner is never assignable via invite
        ];
    }
}
'@
[System.IO.File]::WriteAllText("app\Http\Requests\InviteMemberRequest.php", $c0, $enc)
Write-Host "  Created: app\Http\Requests\InviteMemberRequest.php"

$c1 = @'
<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateMemberRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'role' => ['sometimes', 'in:admin,member,viewer'],
            'status' => ['sometimes', 'in:active,suspended'],
        ];
    }
}
'@
[System.IO.File]::WriteAllText("app\Http\Requests\UpdateMemberRequest.php", $c1, $enc)
Write-Host "  Created: app\Http\Requests\UpdateMemberRequest.php"

$c2 = @'
<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateWorkspaceRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name' => ['sometimes', 'string', 'max:120'],
        ];
    }
}
'@
[System.IO.File]::WriteAllText("app\Http\Requests\UpdateWorkspaceRequest.php", $c2, $enc)
Write-Host "  Created: app\Http\Requests\UpdateWorkspaceRequest.php"

$c3 = @'
<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class WorkspaceMemberResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'role' => $this->role,
            'status' => $this->status,
            'invited_at' => $this->invited_at,
            'joined_at' => $this->joined_at,
            'user' => $this->whenLoaded('user', fn () => [
                'id' => $this->user->id,
                'name' => $this->user->name,
                'email' => $this->user->email,
                'avatar_url' => $this->user->avatar_url,
            ]),
        ];
    }
}
'@
[System.IO.File]::WriteAllText("app\Http\Resources\WorkspaceMemberResource.php", $c3, $enc)
Write-Host "  Created: app\Http\Resources\WorkspaceMemberResource.php"

$c4 = @'
<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\UpdateWorkspaceRequest;
use App\Models\Workspace;
use Illuminate\Http\Request;

class WorkspaceController extends Controller
{
    /**
     * GET /api/v1/workspace
     */
    public function show(Request $request)
    {
        $workspaceId = $request->attributes->get('workspace_id');
        $workspace = Workspace::findOrFail($workspaceId);

        return response()->json([
            'data' => $workspace,
            'meta' => null,
            'error' => null,
        ]);
    }

    /**
     * PATCH /api/v1/workspace
     * Requires ensure.admin (owner/admin only).
     */
    public function update(UpdateWorkspaceRequest $request)
    {
        $workspaceId = $request->attributes->get('workspace_id');
        $workspace = Workspace::findOrFail($workspaceId);

        $workspace->fill($request->only(['name']));
        $workspace->save();

        return response()->json([
            'data' => $workspace,
            'meta' => null,
            'error' => null,
        ]);
    }
}
'@
[System.IO.File]::WriteAllText("app\Http\Controllers\Api\V1\WorkspaceController.php", $c4, $enc)
Write-Host "  Created: app\Http\Controllers\Api\V1\WorkspaceController.php"

$c5 = @'
<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\InviteMemberRequest;
use App\Http\Requests\UpdateMemberRequest;
use App\Http\Resources\WorkspaceMemberResource;
use App\Models\User;
use App\Models\WorkspaceMember;
use Illuminate\Http\Request;

class MemberController extends Controller
{
    /**
     * GET /api/v1/workspace/members
     * Any active member of the workspace can view the roster.
     */
    public function index(Request $request)
    {
        $workspaceId = $request->attributes->get('workspace_id');

        $members = WorkspaceMember::where('workspace_id', $workspaceId)
            ->with('user')
            ->orderByRaw("FIELD(role, 'owner', 'admin', 'member', 'viewer')")
            ->get();

        return response()->json([
            'data' => WorkspaceMemberResource::collection($members),
            'meta' => ['total' => $members->count()],
            'error' => null,
        ]);
    }

    /**
     * POST /api/v1/workspace/members/invite
     * Requires ensure.admin.
     *
     * NOTE: Pulse doesn't send real invite emails yet (no mail provider
     * wired up). The person being invited must already have a Pulse
     * account under this email -- this endpoint attaches them to the
     * workspace directly with status "invited". Wiring up
     * Illuminate\Notifications for a proper "sign up to join" email flow
     * is a natural next step once a mail driver (e.g. Postmark, SES) is
     * configured.
     */
    public function invite(InviteMemberRequest $request)
    {
        $workspaceId = $request->attributes->get('workspace_id');

        $invitedUser = User::where('email', $request->email)->first();

        if (! $invitedUser) {
            return response()->json([
                'data' => null,
                'meta' => null,
                'error' => 'No Pulse account found for that email yet. Ask them to sign up first, then invite them again.',
            ], 422);
        }

        $existing = WorkspaceMember::where('workspace_id', $workspaceId)
            ->where('user_id', $invitedUser->id)
            ->first();

        if ($existing) {
            return response()->json([
                'data' => null,
                'meta' => null,
                'error' => 'This person is already a member of the workspace.',
            ], 422);
        }

        $member = WorkspaceMember::create([
            'workspace_id' => $workspaceId,
            'user_id' => $invitedUser->id,
            'role' => $request->role,
            'status' => 'invited',
            'invited_at' => now(),
        ]);

        $member->load('user');

        return response()->json([
            'data' => new WorkspaceMemberResource($member),
            'meta' => null,
            'error' => null,
        ], 201);
    }

    /**
     * PATCH /api/v1/workspace/members/{member}
     * Requires ensure.admin. Cannot modify the workspace owner.
     */
    public function update(UpdateMemberRequest $request, WorkspaceMember $member)
    {
        $this->authorizeWorkspace($request, $member);

        if ($member->role === 'owner') {
            return response()->json([
                'data' => null,
                'meta' => null,
                'error' => "The workspace owner's role cannot be changed.",
            ], 422);
        }

        $member->fill($request->only(['role', 'status']));
        if ($request->input('status') === 'active' && ! $member->joined_at) {
            $member->joined_at = now();
        }
        $member->save();

        $member->load('user');

        return response()->json([
            'data' => new WorkspaceMemberResource($member),
            'meta' => null,
            'error' => null,
        ]);
    }

    /**
     * DELETE /api/v1/workspace/members/{member}
     * Requires ensure.admin. Cannot remove the workspace owner.
     */
    public function destroy(Request $request, WorkspaceMember $member)
    {
        $this->authorizeWorkspace($request, $member);

        if ($member->role === 'owner') {
            return response()->json([
                'data' => null,
                'meta' => null,
                'error' => 'The workspace owner cannot be removed.',
            ], 422);
        }

        $member->delete();

        return response()->json([
            'data' => ['message' => 'Member removed.'],
            'meta' => null,
            'error' => null,
        ]);
    }

    private function authorizeWorkspace(Request $request, WorkspaceMember $member): void
    {
        abort_unless(
            $member->workspace_id === $request->attributes->get('workspace_id'),
            404
        );
    }
}
'@
[System.IO.File]::WriteAllText("app\Http\Controllers\Api\V1\MemberController.php", $c5, $enc)
Write-Host "  Created: app\Http\Controllers\Api\V1\MemberController.php"

$c6 = @'
<?php

use App\Http\Controllers\Api\V1\AiController;
use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\CalendarEventController;
use App\Http\Controllers\Api\V1\MemberController;
use App\Http\Controllers\Api\V1\NoteController;
use App\Http\Controllers\Api\V1\TaskController;
use App\Http\Controllers\Api\V1\WorkspaceController;
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

            Route::get('workspace', [WorkspaceController::class, 'show']);
            Route::get('workspace/members', [MemberController::class, 'index']);

            Route::prefix('ai')->group(function () {
                Route::post('tasks/suggest', [AiController::class, 'suggestTask']);
                Route::post('notes/summarize', [AiController::class, 'summarizeNote']);
                Route::post('notes/rewrite', [AiController::class, 'rewriteNote']);
                Route::post('notes/grammar-fix', [AiController::class, 'fixGrammar']);
            });

            // Admin/owner-only actions within a workspace
            Route::middleware('ensure.admin')->group(function () {
                Route::patch('workspace', [WorkspaceController::class, 'update']);
                Route::post('workspace/members/invite', [MemberController::class, 'invite']);
                Route::patch('workspace/members/{member}', [MemberController::class, 'update']);
                Route::delete('workspace/members/{member}', [MemberController::class, 'destroy']);
            });
        });
    });
});
'@
[System.IO.File]::WriteAllText("routes\api.php", $c6, $enc)
Write-Host "  Created: routes\api.php"

Write-Host "All Phase 5 files created." -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  php artisan config:clear"
Write-Host "  (restart php artisan serve - no new migration needed)"
