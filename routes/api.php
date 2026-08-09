<?php

use App\Http\Controllers\Api\V1\AiController;
use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\CalendarEventController;
use App\Http\Controllers\Api\V1\DashboardController;
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
            Route::get('dashboard/summary', [DashboardController::class, 'summary']);

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