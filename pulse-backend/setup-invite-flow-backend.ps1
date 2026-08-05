# Pulse Backend - Invite accept/decline flow (BOM-safe)
# Run from inside your pulse-backend folder:
#   powershell -ExecutionPolicy Bypass -File setup-invite-flow.ps1

Write-Host "Adding invite accept/decline flow..." -ForegroundColor Cyan

$enc = New-Object System.Text.UTF8Encoding $false

$c0 = @'
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
            'workspace' => $this->whenLoaded('workspace', fn () => [
                'id' => $this->workspace->id,
                'name' => $this->workspace->name,
            ]),
        ];
    }
}
'@
[System.IO.File]::WriteAllText("app\Http\Resources\WorkspaceMemberResource.php", $c0, $enc)
Write-Host "  Updated: app\Http\Resources\WorkspaceMemberResource.php"

$c1 = @'
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
     * NOTE: Pulse doesn't send real invite emails yet. The invited person
     * must already have a Pulse account under this email. They land in
     * "invited" status and must explicitly accept (see accept() below)
     * before they show up as an active member or can access the
     * workspace's data.
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
     * POST /api/v1/workspace/members/{member}/accept
     * Self-service -- the invited person accepts their OWN pending
     * invitation. Not gated by ensure.admin (they're not a member yet,
     * so they'd never pass that check) or ensure.workspace.member (they
     * may not have an active workspace context for this workspace at
     * all until they accept). Ownership is verified directly instead.
     */
    public function accept(Request $request, WorkspaceMember $member)
    {
        abort_unless($member->user_id === $request->user()->id, 403, 'This invitation is not addressed to you.');

        if ($member->status !== 'invited') {
            return response()->json([
                'data' => null,
                'meta' => null,
                'error' => 'This invitation is no longer pending.',
            ], 422);
        }

        $member->status = 'active';
        $member->joined_at = now();
        $member->save();

        $member->load(['user', 'workspace']);

        return response()->json([
            'data' => new WorkspaceMemberResource($member),
            'meta' => null,
            'error' => null,
        ]);
    }

    /**
     * POST /api/v1/workspace/members/{member}/decline
     * Self-service -- the invited person declines, removing the pending
     * membership row entirely (as if they were never invited).
     */
    public function decline(Request $request, WorkspaceMember $member)
    {
        abort_unless($member->user_id === $request->user()->id, 403, 'This invitation is not addressed to you.');

        if ($member->status !== 'invited') {
            return response()->json([
                'data' => null,
                'meta' => null,
                'error' => 'This invitation is no longer pending.',
            ], 422);
        }

        $member->delete();

        return response()->json([
            'data' => ['message' => 'Invitation declined.'],
            'meta' => null,
            'error' => null,
        ]);
    }

    /**
     * PATCH /api/v1/workspace/members/{member}
     * Requires ensure.admin. Cannot modify the workspace owner.
     * (Admins can still force-activate/suspend/change role for
     * already-accepted members -- this is separate from the person's own
     * accept/decline action above.)
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
[System.IO.File]::WriteAllText("app\Http\Controllers\Api\V1\MemberController.php", $c1, $enc)
Write-Host "  Updated: app\Http\Controllers\Api\V1\MemberController.php"

$c2 = @'
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

        // Self-service invitation response -- deliberately OUTSIDE
        // ensure.workspace.member, since the person may not have an
        // active workspace context for this workspace until they accept.
        Route::post('workspace/members/{member}/accept', [MemberController::class, 'accept']);
        Route::post('workspace/members/{member}/decline', [MemberController::class, 'decline']);

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
[System.IO.File]::WriteAllText("routes\api.php", $c2, $enc)
Write-Host "  Updated: routes\api.php"

Write-Host "Done. Restart php artisan serve." -ForegroundColor Green
