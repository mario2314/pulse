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