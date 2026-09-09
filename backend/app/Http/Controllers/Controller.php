<?php

namespace App\Http\Controllers;

abstract class Controller
{
    protected function success(mixed $data = null, string $message = 'Operación exitosa.', int $status = 200)
    {
        return response()->json([
            'success' => true,
            'message' => $message,
            'data' => $data,
        ], $status);
    }

    protected function error(string $message, int $status = 400, array $errors = [])
    {
        return response()->json([
            'success' => false,
            'message' => $message,
            'errors' => $errors,
        ], $status);
    }
}

