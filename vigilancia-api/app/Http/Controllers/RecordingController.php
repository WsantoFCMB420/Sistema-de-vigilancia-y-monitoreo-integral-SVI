<?php

namespace App\Http\Controllers;

use App\Models\Device;
use App\Models\Recording;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\URL;
use Symfony\Component\Process\ExecutableFinder;
use Symfony\Component\Process\Process;

/**
 * Grabaciones de las cámaras.
 *
 * La app graba un clip de la cámara local (webcam o celular) y lo sube aquí.
 * Los archivos se guardan en storage/app/recordings (fuera de public), así que
 * solo se pueden ver con un enlace firmado que vence a los 30 minutos.
 */
class RecordingController extends Controller
{
    private const EXTENSIONS = ['webm', 'mp4', 'mov', 'mkv'];
    private const TZ = 'America/Bogota';

    // ── GET /recordings?device_id= ────────────────────────────────
    public function index(Request $request)
    {
        $user  = $request->user();
        $query = Recording::with('device:id,title')->latest();

        if ($user->role !== 'admin') {
            $query->where('user_id', $user->id);
        }
        if ($request->filled('device_id')) {
            $query->where('device_id', (int) $request->device_id);
        }

        return response()->json(
            $query->limit(100)->get()->map(fn(Recording $r) => $this->present($r))
        );
    }

    // ── POST /recordings (multipart: file, device_id, duration_seconds) ──
    public function store(Request $request)
    {
        $validated = $request->validate([
            'file'             => 'required|file|max:51200', // 50 MB
            'device_id'        => 'nullable|integer|exists:devices,id',
            'duration_seconds' => 'nullable|integer|min:0|max:3600',
        ], [
            'file.required' => 'No se recibió el video.',
            'file.max'      => 'El video supera los 50 MB.',
        ]);

        $user = $request->user();
        $file = $request->file('file');

        $extension = strtolower($file->getClientOriginalExtension() ?: 'webm');
        $mime      = (string) ($file->getMimeType() ?: $file->getClientMimeType());
        $isVideo   = str_starts_with($mime, 'video/') || $mime === 'application/octet-stream';
        if (!in_array($extension, self::EXTENSIONS, true) || !$isVideo) {
            return response()->json([
                'message' => 'Formato de video no permitido.',
                'errors'  => ['file' => ['Solo se aceptan videos webm, mp4, mov o mkv.']],
            ], 422);
        }

        // Solo se puede grabar una cámara propia (o cualquiera si es admin).
        if (!empty($validated['device_id'])) {
            $device = Device::findOrFail($validated['device_id']);
            if ($user->role !== 'admin' && (int) $device->user_id !== (int) $user->id) {
                return response()->json(['message' => 'No tienes acceso a este dispositivo.'], 403);
            }
        }

        $path = $file->storeAs(
            'recordings/' . $user->id,
            now()->format('Ymd_His') . '_' . bin2hex(random_bytes(4)) . '.' . $extension,
            'local'
        );

        // Los WebM del navegador no traen índice; si el servidor tiene ffmpeg,
        // se reescribe el archivo (sin recomprimir) para que se pueda adelantar.
        if ($extension === 'webm') {
            $this->remuxWebm(Storage::disk('local')->path($path));
        }

        $recording = Recording::create([
            'user_id'          => $user->id,
            'device_id'        => $validated['device_id'] ?? null,
            'file_path'        => $path,
            'mime_type'        => str_starts_with($mime, 'video/') ? $mime : 'video/' . ($extension === 'mov' ? 'quicktime' : $extension),
            'size_bytes'       => Storage::disk('local')->size($path),
            'duration_seconds' => $validated['duration_seconds'] ?? 0,
        ]);

        return response()->json([
            'message'   => 'Grabación guardada',
            'recording' => $this->present($recording->load('device:id,title')),
        ], 201);
    }

    // ── DELETE /recordings/{id} ───────────────────────────────────
    public function destroy(Request $request, $id)
    {
        $recording = Recording::findOrFail($id);
        if (!$this->canAccess($request, $recording)) {
            return response()->json(['message' => 'No tienes acceso a esta grabación.'], 403);
        }

        Storage::disk('local')->delete($recording->file_path);
        $recording->delete();

        return response()->json(['message' => 'Grabación eliminada']);
    }

    // ── GET /recordings/{id}/file (enlace firmado, sin token) ──────
    public function file(Request $request, $id)
    {
        $recording = Recording::findOrFail($id);
        $disk = Storage::disk('local');
        if (!$disk->exists($recording->file_path)) {
            return response()->json(['message' => 'El archivo ya no existe.'], 404);
        }

        // BinaryFileResponse responde a peticiones por rangos, así el
        // reproductor puede adelantar y retroceder.
        return response()->file($disk->path($recording->file_path), [
            'Content-Type'           => $recording->mime_type,
            'X-Content-Type-Options' => 'nosniff',
            'Cache-Control'          => 'private, max-age=1800',
        ]);
    }

    private function remuxWebm(string $absolutePath): void
    {
        try {
            $ffmpeg = (new ExecutableFinder())->find('ffmpeg');
            if (!$ffmpeg) {
                return;
            }
            $tmp = $absolutePath . '.remux.webm';
            $process = new Process([$ffmpeg, '-y', '-v', 'error', '-i', $absolutePath, '-map', '0', '-c', 'copy', $tmp]);
            $process->setTimeout(60);
            $process->run();
            if ($process->isSuccessful() && is_file($tmp) && filesize($tmp) > 0) {
                rename($tmp, $absolutePath);
            } elseif (is_file($tmp)) {
                @unlink($tmp);
            }
        } catch (\Throwable $e) {
            // Sin ffmpeg el archivo queda como llegó; la app ya le agrega la duración.
        }
    }

    private function canAccess(Request $request, Recording $recording): bool
    {
        $user = $request->user();
        return $user->role === 'admin' || (int) $recording->user_id === (int) $user->id;
    }

    private function present(Recording $r): array
    {
        return [
            'id'               => $r->id,
            'device_id'        => $r->device_id,
            'device_name'      => optional($r->device)->title,
            'mime_type'        => $r->mime_type,
            'size_bytes'       => $r->size_bytes,
            'duration_seconds' => $r->duration_seconds,
            'created_at'       => $r->created_at?->toIso8601ZuluString(),
            'local_date'       => $r->created_at?->copy()->setTimezone(self::TZ)->format('Y-m-d'),
            'local_time'       => $r->created_at?->copy()->setTimezone(self::TZ)->format('H:i'),
            // Ruta relativa firmada: la firma no depende de http/https ni del
            // dominio, porque el proxy de alwaysdata puede cambiar el esquema.
            'url'              => URL::temporarySignedRoute(
                'recordings.file', now()->addMinutes(30), ['id' => $r->id], absolute: false
            ),
        ];
    }
}
