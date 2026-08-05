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