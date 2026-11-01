// UUID version 7 (RFC 9562 §5.7), with a monotonic counter.
// from_millis writes an explicit 10-byte random block. new:
// a process-local 42-bit counter that reseeds each millisecond, ignores a
// clock step backward, and bumps the timestamp if the counter wraps.
// The counter occupies the high bits of rand_a and rand_b. The rest is random.

import std;
import os;
import uuid;

namespace uuid7;

const RESEED_MASK: u64 = 0x1ffffffffff;
const MAX_COUNTER: u64 = 0x3ffffffffff;

// Two u64s, hi is the more significant half.
struct Wide { hi: u64, lo: u64 }

struct ContextV7 {
    last_seed: u64,
    seconds: u64,
    nanos: u32,
    counter: u64,
    adjust_ns: u64,
    bits: i64,
    factor: u64,
    mask: u64,
    shift: u64,
    rng: u64,
}

var shared: ContextV7;
var shared_on = false;

fn from_millis(unix_ms: u64, rand: u8[:]) -> uuid::Id, bool {
    if unix_ms >> 48 != 0 || rand.len != 10 { return uuid::nil(), false; }
    var id = uuid::Id { b: [0; 16] };
    var ms = unix_ms;
    for i in 0..6 {
        id.b[5 - i] = ms as! u8;
        ms = ms >> 8;
    }
    id.b[6] = 0x70 | (rand[0] & 0x0f);
    id.b[7] = rand[1];
    id.b[8] = 0x80 | (rand[2] & 0x3f);
    for i in 0..7 { id.b[9 + i] = rand[3 + i]; }
    return id, true;
}

fn unix_ms(id: uuid::Id) -> u64 {
    if uuid::version(id) != 7 || uuid::variant(id) != 2 { abort("uuid7: not a version 7 uuid"); }
    var ms: u64 = 0;
    for i in 0..6 { ms = (ms << 8) | id.b[i]; }
    return ms;
}

fn context(seed: u64) -> ContextV7 {
    return ContextV7 {
        last_seed: 0, seconds: 0, nanos: 0, counter: 0, adjust_ns: 0,
        bits: 0, factor: 0, mask: 0, shift: 0, rng: seed,
    };
}

fn adjust_by_millis(c: ContextV7&, millis: u32) { c.adjust_ns = millis * 1000000; }

fn set_precision(c: ContextV7&, bits_in: i64) {
    var bits = bits_in;
    if bits > 12 { bits = 12; }
    if bits < 0 { bits = 0; }
    c.bits = bits;
    if bits == 0 {
        c.factor = 0;
        c.mask = 0;
        c.shift = 0;
        return;
    }
    var ones: u64 = 0;
    ones = ~ones;
    c.mask = ones >> (22 + bits);
    c.shift = (42 - bits) as u64;
    var p: u64 = 1;
    for _i in 0..bits { p = p * 2; }
    c.factor = 999999 / p + 1;
}

fn mix(c: ContextV7&) -> u64 {
    c.rng = c.rng + 11400714819323198485;
    var z = c.rng;
    z = (z ^ (z >> 30)) * 13787848793156543929;
    z = (z ^ (z >> 27)) * 10723151780598845931;
    return z ^ (z >> 31);
}

fn apply_adjust(seconds: u64, nanos: u32, by_ns: u64) -> u64, u32 {
    if by_ns == 0 { return seconds, nanos; }
    let sum = nanos + by_ns;
    return seconds + sum / 1000000000, (sum % 1000000000) as! u32;
}

fn milli_of(seconds: u64, nanos: u32) -> u64 {
    seconds * 1000 + nanos / 1000000
}

fn apply_precision(c: ContextV7&, counter: u64, nanos: u32) -> u64 {
    if c.bits == 0 { return counter; }
    let additional = (nanos % 1000000) / c.factor;
    return (counter & c.mask) | (additional << c.shift);
}

// Returns the 42-bit counter and the timestamp to encode.
fn step(c: ContextV7&, seconds: u64, nanos: u32) -> u64, u64, u32 {
    var sec = seconds;
    var ns = nanos;
    sec, ns = apply_adjust(sec, ns, c.adjust_ns);
    let incoming = milli_of(sec, ns);
    var use_sec = sec;
    var use_ns = ns;
    var reseed = false;
    if incoming > c.last_seed {
        reseed = true;
    } else if incoming == c.last_seed {
        use_sec = c.seconds;
        use_ns = c.nanos;
        if ns > use_ns { use_ns = ns; }
        reseed = false;
    } else {
        use_sec = c.seconds;
        use_ns = c.nanos;
    }
    var counter: u64 = 0;
    if reseed {
        counter = apply_precision(c, mix(c) & RESEED_MASK, use_ns);
    } else {
        counter = apply_precision(c, c.counter, use_ns) + 1;
        if counter > MAX_COUNTER {
            sec, ns = apply_adjust(use_sec, use_ns, 1000000);
            use_sec = sec;
            use_ns = ns;
            counter = apply_precision(c, mix(c) & RESEED_MASK, use_ns);
        }
    }
    c.last_seed = milli_of(use_sec, use_ns);
    c.seconds = use_sec;
    c.nanos = use_ns;
    c.counter = counter;
    return counter, use_sec, use_ns;
}

fn w_shl(a: Wide, n: i64) -> Wide {
    if n <= 0 { return a; }
    if n >= 128 { return Wide { hi: 0, lo: 0 }; }
    if n >= 64 { return Wide { hi: a.lo << (n - 64), lo: 0 }; }
    return Wide { hi: (a.hi << n) | (a.lo >> (64 - n)), lo: a.lo << n };
}

fn w_shr(a: Wide, n: i64) -> Wide {
    if n <= 0 { return a; }
    if n >= 128 { return Wide { hi: 0, lo: 0 }; }
    if n >= 64 { return Wide { hi: 0, lo: a.hi >> (n - 64) }; }
    return Wide { hi: a.hi >> n, lo: (a.lo >> n) | (a.hi << (64 - n)) };
}

fn w_and(a: Wide, b: Wide) -> Wide { Wide { hi: a.hi & b.hi, lo: a.lo & b.lo } }
fn w_or(a: Wide, b: Wide) -> Wide { Wide { hi: a.hi | b.hi, lo: a.lo | b.lo } }

fn w_not(a: Wide) -> Wide {
    var ones: u64 = 0;
    ones = ~ones;
    return Wide { hi: a.hi ^ ones, lo: a.lo ^ ones };
}

fn w_max() -> Wide {
    var ones: u64 = 0;
    ones = ~ones;
    return Wide { hi: ones, lo: ones };
}

// bits is the counter width. rand fills the bits the counter does not.
fn layout(millis: u64, counter: u64, bits_in: i64, rand: Wide) -> uuid::Id {
    var bits = bits_in;
    if bits > 128 { bits = 128; }
    var c = Wide { hi: 0, lo: counter };
    if bits > 74 {
        c = w_shr(c, bits - 74);
        bits = 74;
    }
    if bits > 12 {
        let mask = w_shl(w_max(), bits - 12);
        c = w_or(w_and(c, w_not(mask)), w_shl(w_and(c, mask), 2));
        bits += 2;
    }
    var mixed = rand;
    if bits != 0 {
        let shift = 124 - bits;
        let keep = w_shr(w_max(), 128 - shift);
        mixed = w_or(w_and(rand, keep), w_shl(c, shift));
    }
    var raw: u8[10] = [0; 10];
    var hi = mixed.hi;
    for i in 0..8 { raw[7 - i] = hi as! u8; hi = hi >> 8; }
    raw[8] = (mixed.lo >> 56) as! u8;
    raw[9] = (mixed.lo >> 48) as! u8;
    let id, ok = from_millis(millis, raw);
    if !ok { abort("uuid7: timestamp does not fit"); }
    return id;
}

fn fresh() -> Wide { Wide { hi: random_seed(), lo: random_seed() } }

fn from_context(c: ContextV7&, seconds: u64, nanos: u32) -> uuid::Id {
    let counter, sec, ns = step(c, seconds, nanos);
    let millis = sec * 1000 + ns / 1000000;
    return layout(millis, counter, 42, fresh());
}

fn from_ns(ns: i64) -> uuid::Id, bool {
    if ns < 0 { return uuid::nil(), false; }
    if !shared_on {
        shared = context(random_seed());
        shared_on = true;
    }
    let seconds = (ns / 1000000000) as u64;
    let nanos = (ns % 1000000000) as! u32;
    return from_context(shared, seconds, nanos), true;
}

fn new() -> uuid::Id, bool {
    return from_ns(time_ns());
}

fn parse(s: u8[:]) -> uuid::Id, bool {
    let id, ok = uuid::parse(s);
    if !ok || uuid::version(id) != 7 || uuid::variant(id) != 2 {
        return uuid::nil(), false;
    }
    return id, true;
}
