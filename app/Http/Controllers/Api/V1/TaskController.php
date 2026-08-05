<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreTaskRequest;
use App\Http\Requests\UpdateTaskRequest;
use App\Http\Resources\TaskResource;
use App\Models\Task;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class TaskController extends Controller
{
    /**
     * GET /api/v1/tasks
     * Filters: status, priority, category_id, label_id, assigned_to, q (search title)
     */
    public function index(Request $request)
    {
        $workspaceId = $request->attributes->get('workspace_id');

        $query = Task::query()
            ->where('workspace_id', $workspaceId)
            ->with(['category', 'labels', 'assignee']);

        $query->when($request->filled('status'), fn ($q) => $q->where('status', $request->status));
        $query->when($request->filled('priority'), fn ($q) => $q->where('priority', $request->priority));
        $query->when($request->filled('category_id'), fn ($q) => $q->where('category_id', $request->category_id));
        $query->when($request->filled('assigned_to'), fn ($q) => $q->where('assigned_to', $request->assigned_to));
        $query->when($request->filled('label_id'), fn ($q) => $q->whereHas(
            'labels',
            fn ($l) => $l->where('labels.id', $request->label_id)
        ));
        $query->when($request->filled('q'), fn ($q) => $q->where('title', 'like', '%' . $request->q . '%'));

        $tasks = $query->orderByDesc('created_at')->paginate($request->integer('per_page', 20));

        return response()->json([
            'data' => TaskResource::collection($tasks->items()),
            'meta' => [
                'page' => $tasks->currentPage(),
                'per_page' => $tasks->perPage(),
                'total' => $tasks->total(),
            ],
            'error' => null,
        ]);
    }

    /**
     * POST /api/v1/tasks
     */
    public function store(StoreTaskRequest $request)
    {
        $workspaceId = $request->attributes->get('workspace_id');

        $task = DB::transaction(function () use ($request, $workspaceId) {
            $task = Task::create([
                'workspace_id' => $workspaceId,
                'created_by' => $request->user()->id,
                'category_id' => $request->category_id,
                'assigned_to' => $request->assigned_to,
                'title' => $request->title,
                'description' => $request->description,
                'status' => $request->input('status', 'todo'),
                'priority' => $request->input('priority', 'medium'),
                'due_date' => $request->due_date,
                'ai_generated' => $request->boolean('ai_generated'),
            ]);

            if ($request->filled('label_ids')) {
                $task->labels()->sync($request->label_ids);
            }

            return $task;
        });

        $task->load(['category', 'labels', 'assignee']);

        return response()->json([
            'data' => new TaskResource($task),
            'meta' => null,
            'error' => null,
        ], 201);
    }

    /**
     * GET /api/v1/tasks/{task}
     */
    public function show(Request $request, Task $task)
    {
        $this->authorizeWorkspace($request, $task);

        $task->load(['category', 'labels', 'assignee']);

        return response()->json([
            'data' => new TaskResource($task),
            'meta' => null,
            'error' => null,
        ]);
    }

    /**
     * PATCH /api/v1/tasks/{task}
     * Also used for drag-drop status changes from the Kanban board.
     */
    public function update(UpdateTaskRequest $request, Task $task)
    {
        $this->authorizeWorkspace($request, $task);

        $task->fill($request->only([
            'title', 'description', 'status', 'priority',
            'category_id', 'assigned_to', 'due_date',
        ]));
        $task->save();

        if ($request->has('label_ids')) {
            $task->labels()->sync($request->label_ids);
        }

        $task->load(['category', 'labels', 'assignee']);

        return response()->json([
            'data' => new TaskResource($task),
            'meta' => null,
            'error' => null,
        ]);
    }

    /**
     * DELETE /api/v1/tasks/{task}
     */
    public function destroy(Request $request, Task $task)
    {
        $this->authorizeWorkspace($request, $task);

        $task->delete();

        return response()->json([
            'data' => ['message' => 'Task deleted.'],
            'meta' => null,
            'error' => null,
        ]);
    }

    /**
     * Ensures the task belongs to the workspace bound to this request
     * (set by the EnsureWorkspaceMember middleware). Prevents a member of
     * workspace A from reading/editing a task that belongs to workspace B,
     * even if they guess the numeric ID.
     */
    private function authorizeWorkspace(Request $request, Task $task): void
    {
        abort_unless(
            $task->workspace_id === $request->attributes->get('workspace_id'),
            404
        );
    }
}
