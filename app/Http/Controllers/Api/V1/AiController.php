<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\AiNoteActionRequest;
use App\Http\Requests\AiSuggestTaskRequest;
use App\Models\AiUsageLog;
use App\Models\Category;
use App\Services\AiService;
use Illuminate\Http\Request;
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

        $result = $this->aiService->suggestTask($request->input('prompt'), $existingCategories);

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

        // Menggunakan input() alih-alih $request->content langsung
        $result = $this->aiService->summarizeNote($request->input('content'));

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

        // Menggunakan input() alih-alih $request->content langsung
        $result = $this->aiService->rewriteNote(
            $request->input('content'), 
            $request->input('tone', 'concise')
        );

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

        // Menggunakan input() alih-alih $request->content langsung
        $result = $this->aiService->fixGrammar($request->input('content'));

        $this->logUsage($request, $workspaceId, 'grammar_fix', $result['tokens_used']);

        return response()->json([
            'data' => ['corrected' => $result['corrected']],
            'meta' => null,
            'error' => null,
        ]);
    }

    private function logUsage(Request $request, int $workspaceId, string $feature, int $tokensUsed): void
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