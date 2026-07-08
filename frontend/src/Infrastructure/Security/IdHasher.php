<?php
declare(strict_types=1);

namespace E258Tech\Infrastructure\Security;

/**
 * Obfuscates integer IDs for browser-facing URLs.
 *
 * Uses the same bijective XOR + rotation cipher as Go's internal/idhash package.
 * Salt is derived from JWT_SECRET so both sides produce identical encodings.
 *
 * encode(id) → opaque URL-safe string
 * decode(s)  → original integer (PHP-side decode not needed in most cases;
 *              Go middleware decodes path/query params transparently)
 */
final class IdHasher
{
    private int $k1;
    private int $k2;

    public function __construct(string $secret)
    {
        $h = hash('sha256', 'nexora:idhash:v1:' . $secret, true);
        // Big-endian unsigned 32-bit — matches Go binary.BigEndian.Uint32
        [, $this->k1] = unpack('N', substr($h, 0, 4));
        [, $this->k2] = unpack('N', substr($h, 4, 4));
    }

    /** Encode a positive integer ID into a short URL-safe string. */
    public function encode(int $id): string
    {
        if ($id <= 0) {
            return '0';
        }
        $h = ($this->rotl32(($id & 0xFFFFFFFF) ^ $this->k1, 13)) ^ $this->k2;
        return $this->toBase36($h & 0xFFFFFFFF);
    }

    /** Expose k1/k2 so the JS helper can replicate encoding client-side. */
    public function k1(): int { return $this->k1; }
    public function k2(): int { return $this->k2; }

    /** Decode a hash string back to integer (mirrors Go Hasher.Decode). */
    public function decode(string $s): int
    {
        if ($s === '0' || $s === '') {
            return 0;
        }
        $n = $this->fromBase36($s);
        $v = ($this->rotl32(($n & 0xFFFFFFFF) ^ $this->k2, 19)) ^ $this->k1;
        return (int) ($v & 0xFFFFFFFF);
    }

    private function rotl32(int $x, int $n): int
    {
        $x &= 0xFFFFFFFF;
        return (($x << $n) | ($x >> (32 - $n))) & 0xFFFFFFFF;
    }

    private function toBase36(int $n): string
    {
        if ($n === 0) {
            return '0';
        }
        $chars = '0123456789abcdefghijklmnopqrstuvwxyz';
        $result = '';
        while ($n > 0) {
            $result = $chars[$n % 36] . $result;
            $n = intdiv($n, 36);
        }
        return $result;
    }

    private function fromBase36(string $s): int
    {
        $chars = '0123456789abcdefghijklmnopqrstuvwxyz';
        $n = 0;
        foreach (str_split($s) as $c) {
            $pos = strpos($chars, $c);
            if ($pos === false) {
                return 0;
            }
            $n = $n * 36 + $pos;
        }
        return $n;
    }
}
