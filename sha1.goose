// SHA-1 (FIPS 180-4). Used by UUID version 5. Words are wrapping u32.
// hash returns the first 16 bytes of the 20-byte digest.

import std;

namespace sha1;

const MAX_BYTES: u64 = 0x2000000000000000;

struct Ctx {
    h: u32[5],
    buf: u8[64],
    n: i64,
    bytes: u64,
}

fn rotl(x: u32, n: u32) -> u32 { (x << n) | (x >> (32 - n)) }

fn load_be32(s: u8[:], i: i64) -> u32 {
    let c = s[i..i + 4];
    return (c[0] as u32) << 24 | (c[1] as u32) << 16 | (c[2] as u32) << 8 | c[3];
}

fn store_be32(dst: u8[:], at: i64, v: u32) {
    dst[at] = (v >> 24) as! u8;
    dst[at + 1] = (v >> 16) as! u8;
    dst[at + 2] = (v >> 8) as! u8;
    dst[at + 3] = v as! u8;
}

fn store_be64(dst: u8[:], at: i64, v: u64) {
    for i in 0..8 { dst[at + i] = (v >> ((7 - i) * 8)) as! u8; }
}

fn compress(h: u32[5]&, data: u8[:]) {
    var w: u32[80] = [0; 80];
    var i = 0;
    while i + 64 <= data.len {
        let chunk = data[i..i + 64];
        for t in 0..16 { w[t] = load_be32(chunk, 4 * t); }
        for t in 16..80 {
            w[t] = rotl(w[t - 3] ^ w[t - 8] ^ w[t - 14] ^ w[t - 16], 1);
        }
        var a = h[0];
        var b = h[1];
        var c = h[2];
        var d = h[3];
        var e = h[4];
        for t in 0..80 {
            var f: u32 = 0;
            var k: u32 = 0;
            if t < 20 {
                f = (b & c) | (~b & d);
                k = 0x5a827999;
            } else if t < 40 {
                f = b ^ c ^ d;
                k = 0x6ed9eba1;
            } else if t < 60 {
                f = (b & c) | (b & d) | (c & d);
                k = 0x8f1bbcdc;
            } else {
                f = b ^ c ^ d;
                k = 0xca62c1d6;
            }
            let next = rotl(a, 5) + f + e + k + w[t];
            e = d;
            d = c;
            c = rotl(b, 30);
            b = a;
            a = next;
        }
        h[0] += a;
        h[1] += b;
        h[2] += c;
        h[3] += d;
        h[4] += e;
        i += 64;
    }
}

fn init() -> Ctx {
    var c: Ctx = default<Ctx>();
    c.h[0] = 0x67452301;
    c.h[1] = 0xefcdab89;
    c.h[2] = 0x98badcfe;
    c.h[3] = 0x10325476;
    c.h[4] = 0xc3d2e1f0;
    return c;
}

fn update(c: Ctx&, data: u8[:]) {
    let more = data.len as u64;
    if more >= MAX_BYTES - c.bytes { abort("sha1: message is too long"); }
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

fn finish(c: Ctx&) -> u8[20] {
    var h = copy(c.h);
    let n = c.n;
    var tail: u8[128] = [0; 128];
    for i in 0..n { tail[i] = c.buf[i]; }
    tail[n] = 0x80;
    let nblk = if n >= 56 { 128 } else { 64 };
    store_be64(tail, nblk - 8, c.bytes << 3);
    compress(h, tail[..nblk]);
    var out: u8[20] = [0; 20];
    for i in 0..5 { store_be32(out, i * 4, h[i]); }
    return out;
}

// The first 16 bytes of SHA-1(a || b). UUID version 5 discards the rest.
fn hash(a: u8[:], b: u8[:]) -> u8[16] {
    var c = init();
    update(c, a);
    update(c, b);
    let full = finish(c);
    var out: u8[16] = [0; 16];
    for i in 0..16 { out[i] = full[i]; }
    return out;
}
