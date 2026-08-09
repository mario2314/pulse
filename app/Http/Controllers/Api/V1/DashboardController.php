<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\AiUsageLog;
use App\Models\Note;
use App\Models\Task;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    public function summary(Request $request): JsonResponse
    {
        $workspaceId = $request->attributes->get('workspace_id');

        $totalTasks = Task::where('workspace_id', $workspaceId)->count();
        $openTasks = Task::where('workspace_id', $workspaceId)
            ->whereIn('status', ['todo', 'in_progress', 'in_review'])
            ->count();
        $doneTasks = Task::where('workspace_id', $workspaceId)
            ->where('status', 'done')
            ->count();

        $completedPercent = $totalTasks > 0
            ? round(($doneTasks / $totalTasks) * 100)
            : 0;

        $notesCount = Note::where('workspace_id', $workspaceId)->count();

        $aiActionsUsed = AiUsageLog::where('workspace_id', $workspaceId)->count();

        return response()->json([
            'data' => [
                'open_tasks' => $openTasks,
                'completed_percent' => $completedPercent,
                'notes_count' => $notesCount,
                'ai_actions_used' => $aiActionsUsed,
                'ai_actions_limit' => 500,
            ],
            'meta' => null,
            'error' => null,
        ]);
    }
}