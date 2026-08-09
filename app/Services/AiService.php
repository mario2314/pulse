<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use RuntimeException;

class AiService
{
    protected string $apiKey;
    protected string $model;
    protected string $baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

    public function __construct()
    {
        $this->apiKey = env('GROQ_API_KEY', '');
        $this->model = env('GROQ_MODEL', 'llama-3.1-8b-instant');
    }

    /**
     * Memanggil API Groq dengan handling error & retry
     */
    private function askGroq(string $systemPrompt, string $userPrompt, float $temperature = 0.5): array
    {
        $response = Http::withHeaders([
            'Authorization' => 'Bearer ' . $this->apiKey,
            'Content-Type' => 'application/json',
        ])->retry(2, 1000, throw: false)
          ->post($this->baseUrl, [
            'model' => $this->model,
            'messages' => [
                ['role' => 'system', 'content' => $systemPrompt],
                ['role' => 'user', 'content' => $userPrompt]
            ],
            'temperature' => $temperature,
        ]);

        if ($response->failed()) {
            Log::error('Groq AI Request Failed', ['status' => $response->status(), 'body' => $response->body()]);

            if ($response->status() === 429) {
                throw new RuntimeException("Maaf, limit penggunaan AI sedang habis atau sibuk. Silakan coba beberapa saat lagi.");
            }

            throw new RuntimeException("Terjadi masalah saat menghubungkan ke layanan AI.");
        }

        $data = $response->json();
        
        return [
            'content' => trim($data['choices'][0]['message']['content'] ?? ''),
            'tokens_used' => $data['usage']['total_tokens'] ?? 0
        ];
    }

    /**
     * Suggest Task (Generates a single structured task suggestion based on prompt)
     */
    public function suggestTask(string $prompt, array $existingCategories = []): array
    {
        $categoriesJson = json_encode($existingCategories);
        $today = now()->format('Y-m-d, l');
        $systemPrompt = "You are an AI task assistant. Today's date is {$today}. When the prompt implies a relative day (e.g. 'tomorrow', 'friday', 'next week'), compute due_date_suggestion as an actual future date after today in YYYY-MM-DD format -- never reuse a date from your training data. Given a rough task description, respond with ONLY a single JSON object (no markdown, no array, no extra text) with these exact keys: "
            . "title (string, a clear concise task title), "
            . "category_suggestion (string matching one of the available category names if relevant, otherwise null), "
            . "priority (one of: low, medium, high, urgent), "
            . "due_date_suggestion (a date in YYYY-MM-DD format if a deadline is implied, otherwise null), "
            . "subtasks (an array of 2-5 short actionable subtask strings). "
            . "Available categories: {$categoriesJson}";

        $result = $this->askGroq($systemPrompt, $prompt);
        $decoded = json_decode($result['content'], true);

        $priority = strtolower((string) ($decoded['priority'] ?? 'medium'));
        if (! in_array($priority, ['low', 'medium', 'high', 'urgent'], true)) {
            $priority = 'medium';
        }

        return [
            'suggestion' => [
                'title' => $decoded['title'] ?? $prompt,
                'category_suggestion' => $decoded['category_suggestion'] ?? null,
                'priority' => $priority,
                'due_date_suggestion' => $decoded['due_date_suggestion'] ?? null,
                'subtasks' => is_array($decoded['subtasks'] ?? null) ? array_values($decoded['subtasks']) : [],
            ],
            'tokens_used' => $result['tokens_used'],
        ];
    }

    /**
     * Summarize Note
     */
    public function summarizeNote(string $content): array
    {
        $systemPrompt = "You are a professional summarizer. Summarize the text and extract 3-5 key points in Indonesian language. Respond strictly in JSON format with two keys: 'summary' (string) and 'key_points' (array of strings). Do NOT wrap in markdown code blocks.";
        
        $result = $this->askGroq($systemPrompt, $content, 0.3);
        $decoded = json_decode($result['content'], true);

        return [
            'summary' => $decoded['summary'] ?? $result['content'],
            'key_points' => $decoded['key_points'] ?? [],
            'tokens_used' => $result['tokens_used']
        ];
    }

    /**
     * Rewrite Note
     */
    public function rewriteNote(string $content, string $tone = 'concise'): array
    {
        $systemPrompt = "You are an expert editor. Rewrite the text into a '{$tone}' tone in Indonesian language. Return ONLY the rewritten text without quotes, markdown formatting, or conversational filler.";

        $result = $this->askGroq($systemPrompt, $content, 0.5);

        return [
            'rewritten' => trim($result['content'], " \t\n\r\0\x0B\"'"),
            'tokens_used' => $result['tokens_used']
        ];
    }

    /**
     * Fix Grammar
     */
    public function fixGrammar(string $content): array
    {
        $systemPrompt = "You are a professional proofreader. Fix all spelling, punctuation, and grammar errors in the provided text while keeping its original meaning. Return ONLY the corrected text without any explanations or intro text.";

        $result = $this->askGroq($systemPrompt, $content, 0.2);

        return [
            'corrected' => trim($result['content'], " \t\n\r\0\x0B\"'"),
            'tokens_used' => $result['tokens_used']
        ];
    }
}