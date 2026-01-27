<?php

namespace App\Http\Middleware;

use Closure;
use Kreait\Firebase\Factory;

class FirebaseAuth
{
    public function handle($request, Closure $next)
    {
        $token = $request->bearerToken();

        if (!$token) {
            return response()->json(['error'=>'Token missing'],401);
        }

        try {
            $factory = (new Factory)->withServiceAccount(storage_path('app/firebase.json'));
            $auth = $factory->createAuth();
            $verified = $auth->verifyIdToken($token);

            $request->firebaseUser = $verified->claims()->get('sub');
        } catch (\Exception $e) {
            return response()->json(['error'=>'Invalid Firebase Token'],401);
        }

        return $next($request);
    }
}
