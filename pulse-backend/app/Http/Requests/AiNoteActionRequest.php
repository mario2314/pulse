<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class AiNoteActionRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            // The raw markdown content (or selected excerpt) to act on.
            'content' => ['required', 'string', 'max:20000'],
            // Only used by the rewrite endpoint. Ignored elsewhere.
            'tone' => ['nullable', 'string', 'in:concise,formal,friendly,confident'],
        ];
    }
}