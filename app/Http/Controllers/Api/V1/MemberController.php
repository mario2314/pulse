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

        // Sorted in PHP rather than SQL's FIELD() (a MySQL-only function
        // with no direct Postgres equivalent) so this works identically
        // on MySQL and Postgres without database-specific raw SQL.
        $roleOrder = ['owner' => 0, 'admin' => 1, 'member' => 2, 'viewer' => 3];

        $members = WorkspaceMember::where('workspace_id', $workspaceId)
            ->with('user')
            ->get()
            ->sortBy(fn ($m) => $roleOrder[$m->role] ?? 99)
            ->values();

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