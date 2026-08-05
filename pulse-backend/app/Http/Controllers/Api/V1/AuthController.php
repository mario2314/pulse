<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Workspace;
use App\Models\WorkspaceMember;
use Illuminate\Contracts\Auth\Guard;

use Illuminate\Contracts\Auth\StatefulGuard;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;

class AuthController extends Controller
{
    /**
     * Helper privat untuk type hinting Guard agar VS Code tidak membaca return type void.
     *
     * @return Guard|StatefulGuard|\PHPOpenSourceSaver\JWTAuth\JWTGuard|\Tymon\JWTAuth\JWTGuard
     */
    private function guard()
    {
        return Auth::guard('api');
    }

    public function register(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'name' => ['required', 'string', 'max:120'],
            'email' => ['required', 'email', 'max:190', 'unique:users,email'],
            'password' => ['required', 'string', 'min:8', 'confirmed'],
            'workspace_name' => ['required', 'string', 'max:120'],
        ]);

        if ($validator->fails()) {
            return response()->json([
                'data' => null,
                'meta' => null,
                'error' => $validator->errors(),
            ], 422);
        }

        /** @var User $user */
        $user = DB::transaction(function () use ($request) {
            $user = User::create([
                'name' => $request->name,
                'email' => $request->email,
                'password' => Hash::make($request->password),
            ]);

            $workspace = Workspace::create([
                'name' => $request->workspace_name,
                'owner_id' => $user->id,
                'plan' => 'free',
            ]);

            WorkspaceMember::create([
                'workspace_id' => $workspace->id,
                'user_id' => $user->id,
                'role' => 'owner',
                'status' => 'active',
                'joined_at' => now(),
            ]);

            return $user;
        });

        /** @var string $token */
        $token = $this->guard()->login($user);

        return $this->tokenResponse($token, $user);
    }

    public function login(Request $request): JsonResponse
    {
        $credentials = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
        ]);

        /** @var string|false $token */
        $token = $this->guard()->attempt($credentials);

        if (! $token) {
            return response()->json([
                'data' => null,
                'meta' => null,
                'error' => 'Invalid email or password.',
            ], 401);
        }

        /** @var User $user */
        $user = $this->guard()->user();

        return $this->tokenResponse($token, $user);
    }

    public function refresh(): JsonResponse
    {
        /** @var string $token */
        $token = $this->guard()->refresh();

        /** @var User $user */
        $user = $this->guard()->user();

        return $this->tokenResponse($token, $user);
    }

    public function logout(): JsonResponse
    {
        $this->guard()->logout();

        return response()->json([
            'data' => ['message' => 'Logged out successfully.'],
            'meta' => null,
            'error' => null,
        ]);
    }

    public function me(Request $request): JsonResponse
    {
        $user = $request->user()->load('workspaceMemberships.workspace');

        return response()->json([
            'data' => $user,
            'meta' => null,
            'error' => null,
        ]);
    }

    private function tokenResponse(string $token, User $user): JsonResponse
    {
        // Critical: login/register must return the SAME shape as /me,
        // including workspace_memberships. The frontend caches this user
        // object immediately without a follow-up fetch, so if this
        // relation is missing here, workspace-scoped screens (Tasks,
        // Notes, etc.) silently have no workspace id to filter by until
        // the next full page reload re-fetches /me properly.
        $user->load('workspaceMemberships.workspace');

        return response()->json([
            'data' => [
                'user' => $user,
                'access_token' => $token,
                'token_type' => 'bearer',
                'expires_in' => $this->guard()->factory()->getTTL() * 60,
            ],
            'meta' => null,
            'error' => null,
        ]);
    }
}