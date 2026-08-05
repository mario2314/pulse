<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class AiSuggestTaskRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            // The rough, unstructured input the user typed, e.g. "prep client deck"
            'prompt' => ['required', 'string', 'max:500'],
        ];
    }
}
