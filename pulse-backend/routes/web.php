<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');

});
Route::get('/login', function () {
    return response()->json([
        'data' => null,
        'meta' => null,
        'error' => 'Unauthenticated.',
    ], 401);
})->name('login');