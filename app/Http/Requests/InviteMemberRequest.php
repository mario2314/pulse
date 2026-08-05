<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class InviteMemberRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // gated by ensure.admin middleware on the route
    }

    public function rules(): array
    {
        return [
            'email' => ['required', 'email', 'max:190'],
            'role' => ['required', 'in:admin,member,viewer'], // owner is never assignable via invite
        ];
    }
}