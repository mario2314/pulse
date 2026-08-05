<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureAdmin
{
    /**
     * Must run AFTER EnsureWorkspaceMember (needs "membership" attribute set).
     * Used for /admin/* routes.
     */
    public function handle(Request $request, Closure $next): Response
    {
        $membership = $request->attributes->get('membership');

        if (! $membership || ! $membership->isAdminOrOwner()) {
            return response()->json([
                'data' => null,
                'meta' => null,
                'error' => 'Admin access required.',
            ], 403);
        }

        return $next($request);
    }
}
