<?php

namespace App\Http\Middleware;

use App\Models\WorkspaceMember;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureWorkspaceMember
{
    /**
     * Reads X-Workspace-Id header, checks the authenticated user is an
     * active member, and binds the membership onto the request so
     * controllers/policies can use it without re-querying.
     */
    public function handle(Request $request, Closure $next): Response
    {
        $workspaceId = $request->header('X-Workspace-Id');

        if (! $workspaceId) {
            return response()->json([
                'data' => null,
                'meta' => null,
                'error' => 'Missing X-Workspace-Id header.',
            ], 400);
        }

        $membership = WorkspaceMember::where('workspace_id', $workspaceId)
            ->where('user_id', $request->user()->id)
            ->where('status', 'active')
            ->first();

        if (! $membership) {
            return response()->json([
                'data' => null,
                'meta' => null,
                'error' => 'You are not a member of this workspace.',
            ], 403);
        }

        $request->attributes->set('workspace_id', (int) $workspaceId);
        $request->attributes->set('membership', $membership);

        return $next($request);
    }
}
