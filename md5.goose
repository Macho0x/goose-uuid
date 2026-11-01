// MD5 (RFC 1321). Used by UUID version 3. Words are wrapping u32.
// The digest is 16 bytes.

import std;

namespace md5;

const S: u32[64] = [
    7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22,
    5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20,
    4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23,
    6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21,
];

const K: u32[64] = [
    0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee, 0xf57c0faf, 0x4787c62a, 0xa8304613, 0xfd469501,
    0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be, 0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821,
    0xf61e2562, 0xc040b340, 0x265e5a51, 0xe9b6c7aa, 0xd62f105d, 0x02441453, 0xd8a1e681, 0xe7d3fbc8,
    0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed, 0xa9e3e905, 0xfcefa3f8, 0x676f02d9, 0x8d2a4c8a,
    0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c, 0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70,
    0x289b7ec6, 0xeaa127fa, 0xd4ef3085, 0x04881d05, 0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665,
    0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039, 0x655b59c3, 0x8f0ccc92, 0xffeff47d, 0x85845dd1,
    0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1, 0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391,
];

const MAX_BYTES: u64 = 0x2000000000000000;

struct Ctx {
    h: u32[4],
    buf: u8[64],
    n: i64,
    bytes: u64,
}

fn rotl(x: u32, n: u32) -> u32 { (x << n) | (x >> (32 - n)) }

fn load_le32(s: u8[:], i: i64) -> u32 {
    let c = s[i..i + 4];
    return c[0] | (c[1] as u32) << 8 | (c[2] as u32) << 16 | (c[3] as u32) << 24;
}

fn store_le32(dst: u8[:], at: i64, v: u32) {
    dst[at] = v as! u8;
    dst[at + 1] = (v >> 8) as! u8;
    dst[at + 2] = (v >> 16) as! u8;
    dst[at + 3] = (v >> 24) as! u8;
}

fn store_le64(dst: u8[:], at: i64, v: u64) {
    for i in 0..8 { dst[at + i] = (v >> (i * 8)) as! u8; }
}

fn compress(h: u32[4]&, data: u8[:]) {
    var m: u32[16] = [0; 16];
    var i = 0;
    while i + 64 <= data.len {
        let chunk = data[i..i + 64];
        for t in 0..16 { m[t] = load_le32(chunk, 4 * t); }
        var a = h[0];
        var b = h[1];
        var c = h[2];
        var d = h[3];
        for t in 0..64 {
            var f: u32 = 0;
            var g = 0;
            if t < 16 {
                f = (b & c) | (~b & d);
                g = t;
            } else if t < 32 {
                f = (d & b) | (~d & c);
                g = (5 * t + 1) % 16;
            } else if t < 48 {
                f = b ^ c ^ d;
                g = (3 * t + 5) % 16;
            } else {
                f = c ^ (b | ~d);
                g = (7 * t) % 16;
            }
            let next = d;
            d = c;
            c = b;
            b = b + rotl(a + f + K[t] + m[g], S[t]);
            a = next;
        }
        h[0] += a;
        h[1] += b;
        h[2] += c;
        h[3] += d;
        i += 64;
    }
}

fn init() -> Ctx {
    var c: Ctx = default<Ctx>();
    c.h[0] = 0x67452301;
    c.h[1] = 0xefcdab89;
    c.h[2] = 0x98badcfe;
    c.h[3] = 0x10325476;
    return c;
}

fn update(c: Ctx&, data: u8[:]) {
    let more = data.len as u64;
    if more >= MAX_BYTES - c.bytes { abort("md5: message is too long"); }
    c.bytes += more;
    var off = 0;
    if c.n > 0 {
        let space = 64 - c.n;
        var take = data.len;
        if take > space { take = space; }
        for i in 0..take { c.buf[c.n + i] = data[i]; }
        c.n += take;
        off = take;
        if c.n < 64 { return; }
        compress(c.h, c.buf);
        c.n = 0;
    }
    let whole = ((data.len - off) / 64) * 64;
    if whole > 0 { compress(c.h, data[off..off + whole]); }
    off += whole;
    let tail = data.len - off;
    for i in 0..tail { c.buf[i] = data[off + i]; }
    c.n = tail;
}

fn finish(c: Ctx&) -> u8[16] {
    var h = copy(c.h);
    let n = c.n;
    var tail: u8[128] = [0; 128];
    for i in 0..n { tail[i] = c.buf[i]; }
    tail[n] = 0x80;
    let nblk = if n >= 56 { 128 } else { 64 };
    store_le64(tail, nblk - 8, c.bytes << 3);
    compress(h, tail[..nblk]);
    var out: u8[16] = [0; 16];
    for i in 0..4 { store_le32(out, i * 4, h[i]); }
    return out;
}

// MD5(a || b). UUID version 3 hashes the namespace bytes and then the name.
fn hash(a: u8[:], b: u8[:]) -> u8[16] {
    var c = init();
    update(c, a);
    update(c, b);
    return finish(c);
}
