// UUID bytes and text (RFC 9562).
// Versions are separate modules. Importing the package loads this file only.
// Text output is lowercase. parse accepts the dashed form, the 32-digit form,
// "{...}", and "urn:uuid:..." in either hex case.

import std;
import os;

namespace uuid;

struct Id { b: u8[16] }

// A timestamp recovered from a version 1, 6, or 7 UUID.
// counter is 14 bits for versions 1 and 6. Version 7 does not keep one.
struct Time {
    seconds: u64,
    nanos: u32,
    counter: u64,
    bits: u8,
}

// 14-bit clock sequence for versions 1 and 6. The stored count wraps through
// all 16 bits; the value handed out is the low 14.
struct Clock1 { n: u16 }

// 100ns ticks between 1582-10-15 and the Unix epoch.
const TICKS_BETWEEN_EPOCHS: u64 = 0x01B21DD213814000;

const DNS: Id = Id { b: [
    0x6b, 0xa7, 0xb8, 0x10, 0x9d, 0xad, 0x11, 0xd1, 0x80, 0xb4, 0x00, 0xc0, 0x4f, 0xd4, 0x30, 0xc8,
] };
const URL: Id = Id { b: [
    0x6b, 0xa7, 0xb8, 0x11, 0x9d, 0xad, 0x11, 0xd1, 0x80, 0xb4, 0x00, 0xc0, 0x4f, 0xd4, 0x30, 0xc8,
] };
const OID: Id = Id { b: [
    0x6b, 0xa7, 0xb8, 0x12, 0x9d, 0xad, 0x11, 0xd1, 0x80, 0xb4, 0x00, 0xc0, 0x4f, 0xd4, 0x30, 0xc8,
] };
const X500: Id = Id { b: [
    0x6b, 0xa7, 0xb8, 0x14, 0x9d, 0xad, 0x11, 0xd1, 0x80, 0xb4, 0x00, 0xc0, 0x4f, 0xd4, 0x30, 0xc8,
] };

var shared_clock1: Clock1 = Clock1 { n: 0 };
var shared_clock1_on = false;

fn nil() -> Id { Id { b: [0; 16] } }
fn max() -> Id { Id { b: [0xff; 16] } }

fn is_nil(id: Id) -> bool {
    for i in 0..16 { if id.b[i] != 0 { return false; } }
    return true;
}

fn is_max(id: Id) -> bool {
    for i in 0..16 { if id.b[i] != 0xff { return false; } }
    return true;
}

fn version(id: Id) -> u8 { id.b[6] >> 4 }

// The top two bits of octet 8: 0, 1, 2 (RFC 4122), or 3.
fn variant(id: Id) -> u8 { id.b[8] >> 6 }

// Variant class: 0 NCS, 1 RFC 4122, 2 Microsoft, 3 future.
fn variant_kind(id: Id) -> u8 {
    let x = id.b[8];
    if x & 0x80 == 0 { return 0; }
    if x & 0xc0 == 0x80 { return 1; }
    if x & 0xe0 == 0xc0 { return 2; }
    return 3;
}

fn stamp(id: Id&, ver: u8) {
    id.b[6] = (id.b[6] & 0x0f) | (ver << 4);
    id.b[8] = (id.b[8] & 0x3f) | 0x80;
}

fn put_hex(out: u8[>..]&, b: u8) {
    let hex = "0123456789abcdef";
    out.push(hex[b >> 4]);
    out.push(hex[b & 0x0f]);
}

fn format(out: u8[>..]&, id: Id) {
    for i in 0..16 {
        if i == 4 || i == 6 || i == 8 || i == 10 { out.push('-'); }
        put_hex(out, id.b[i]);
    }
}

fn simple(id: Id) -> u8[>..] {
    var out: u8[>..] = [];
    for i in 0..16 { put_hex(out, id.b[i]); }
    return out;
}

fn urn(id: Id) -> u8[>..] {
    var out: u8[>..] = [];
    out.append("urn:uuid:");
    format(out, id);
    return out;
}

fn braced(id: Id) -> u8[>..] {
    var out: u8[>..] = [];
    out.push('{');
    format(out, id);
    out.push('}');
    return out;
}

fn nibble(c: u8) -> u8, bool {
    if c >= '0' && c <= '9' { return c - '0', true; }
    if c >= 'a' && c <= 'f' { return c - 'a' + 10, true; }
    if c >= 'A' && c <= 'F' { return c - 'A' + 10, true; }
    return 0, false;
}

fn parse_hex(s: u8[:]) -> Id, bool {
    if s.len != 32 { return nil(), false; }
    var id = nil();
    for i in 0..16 {
        let hi, okh = nibble(s[i * 2]);
        let lo, okl = nibble(s[i * 2 + 1]);
        if !okh || !okl { return nil(), false; }
        id.b[i] = (hi << 4) | lo;
    }
    return id, true;
}

fn parse_dashed(s: u8[:]) -> Id, bool {
    if s.len != 36 { return nil(), false; }
    if s[8] != '-' || s[13] != '-' || s[18] != '-' || s[23] != '-' { return nil(), false; }
    var id = nil();
    var at = 0;
    for i in 0..16 {
        if at == 8 || at == 13 || at == 18 || at == 23 { at += 1; }
        let hi, okh = nibble(s[at]);
        let lo, okl = nibble(s[at + 1]);
        if !okh || !okl { return nil(), false; }
        id.b[i] = (hi << 4) | lo;
        at += 2;
    }
    return id, true;
}

fn is_urn(s: u8[:]) -> bool {
    let p = "urn:uuid:";
    for i in 0..9 {
        var c = s[i];
        if c >= 'A' && c <= 'Z' { c = c - 'A' + 'a'; }
        if c != p[i] { return false; }
    }
    return true;
}

fn parse(s: u8[:]) -> Id, bool {
    if s.len == 32 { return parse_hex(s); }
    if s.len == 36 { return parse_dashed(s); }
    if s.len == 38 && s[0] == '{' && s[37] == '}' { return parse_dashed(s[1..37]); }
    if s.len == 45 && is_urn(s) { return parse_dashed(s[9..]); }
    return nil(), false;
}

fn from_bytes(b: u8[:]) -> Id {
    if b.len != 16 { abort("uuid: 16 bytes"); }
    var id = nil();
    for i in 0..16 { id.b[i] = b[i]; }
    return id;
}

fn from_bytes_le(b: u8[:]) -> Id {
    if b.len != 16 { abort("uuid: 16 bytes"); }
    var id = nil();
    id.b[0] = b[3];
    id.b[1] = b[2];
    id.b[2] = b[1];
    id.b[3] = b[0];
    id.b[4] = b[5];
    id.b[5] = b[4];
    id.b[6] = b[7];
    id.b[7] = b[6];
    for i in 8..16 { id.b[i] = b[i]; }
    return id;
}

fn bytes_le(id: Id) -> u8[16] {
    var b: u8[16] = [0; 16];
    b[0] = id.b[3];
    b[1] = id.b[2];
    b[2] = id.b[1];
    b[3] = id.b[0];
    b[4] = id.b[5];
    b[5] = id.b[4];
    b[6] = id.b[7];
    b[7] = id.b[6];
    for i in 8..16 { b[i] = id.b[i]; }
    return b;
}

fn from_fields(d1: u32, d2: u16, d3: u16, d4: u8[:]) -> Id {
    if d4.len != 8 { abort("uuid: last field must be 8 bytes"); }
    var id = nil();
    id.b[0] = (d1 >> 24) as! u8;
    id.b[1] = (d1 >> 16) as! u8;
    id.b[2] = (d1 >> 8) as! u8;
    id.b[3] = d1 as! u8;
    id.b[4] = (d2 >> 8) as! u8;
    id.b[5] = d2 as! u8;
    id.b[6] = (d3 >> 8) as! u8;
    id.b[7] = d3 as! u8;
    for i in 0..8 { id.b[8 + i] = d4[i]; }
    return id;
}

fn from_fields_le(d1: u32, d2: u16, d3: u16, d4: u8[:]) -> Id {
    if d4.len != 8 { abort("uuid: last field must be 8 bytes"); }
    var raw: u8[16] = [0; 16];
    raw[0] = d1 as! u8;
    raw[1] = (d1 >> 8) as! u8;
    raw[2] = (d1 >> 16) as! u8;
    raw[3] = (d1 >> 24) as! u8;
    raw[4] = d2 as! u8;
    raw[5] = (d2 >> 8) as! u8;
    raw[6] = d3 as! u8;
    raw[7] = (d3 >> 8) as! u8;
    for i in 0..8 { raw[8 + i] = d4[i]; }
    return from_bytes(raw);
}

fn from_u64_pair(hi: u64, lo: u64) -> Id {
    var id = nil();
    var x = hi;
    for i in 0..8 {
        id.b[7 - i] = x as! u8;
        x = x >> 8;
    }
    x = lo;
    for i in 0..8 {
        id.b[15 - i] = x as! u8;
        x = x >> 8;
    }
    return id;
}

fn u64_pair(id: Id) -> u64, u64 {
    var hi: u64 = 0;
    var lo: u64 = 0;
    for i in 0..8 { hi = (hi << 8) | id.b[i]; }
    for i in 0..8 { lo = (lo << 8) | id.b[8 + i]; }
    return hi, lo;
}

fn random_bytes(dst: u8[:]) {
    var i = 0;
    while i < dst.len {
        var w = random_seed();
        for bit in 0..8 {
            if i >= dst.len { return; }
            dst[i] = (w >> (bit * 8)) as! u8;
            i += 1;
        }
    }
}

fn unix_to_ticks(seconds: u64, nanos: u32) -> u64 {
    TICKS_BETWEEN_EPOCHS + seconds * 10000000 + (nanos as u64) / 100
}

fn ticks_to_unix(ticks: u64) -> u64, u32 {
    let d = ticks - TICKS_BETWEEN_EPOCHS;
    return d / 10000000, ((d % 10000000) * 100) as! u32;
}

fn v1(ticks: u64, counter: u16, node: u8[:]) -> Id {
    if node.len != 6 { abort("uuid: node id must be 6 bytes"); }
    let time_low = (ticks & 0xffffffff) as! u32;
    let time_mid = ((ticks >> 32) & 0xffff) as! u16;
    let time_hi = (((ticks >> 48) & 0x0fff) as! u16) | 0x1000;
    var d4: u8[8] = [0; 8];
    d4[0] = (((counter & 0x3f00) >> 8) as! u8) | 0x80;
    d4[1] = (counter & 0xff) as! u8;
    for i in 0..6 { d4[2 + i] = node[i]; }
    return from_fields(time_low, time_mid, time_hi, d4);
}

fn v6(ticks: u64, counter: u16, node: u8[:]) -> Id {
    if node.len != 6 { abort("uuid: node id must be 6 bytes"); }
    let time_high = ((ticks >> 28) & 0xffffffff) as! u32;
    let time_mid = ((ticks >> 12) & 0xffff) as! u16;
    let time_low = ((ticks & 0x0fff) as! u16) | 0x6000;
    var d4: u8[8] = [0; 8];
    d4[0] = (((counter & 0x3f00) >> 8) as! u8) | 0x80;
    d4[1] = (counter & 0xff) as! u8;
    for i in 0..6 { d4[2 + i] = node[i]; }
    return from_fields(time_high, time_mid, time_low, d4);
}

fn ticks_v1(id: Id) -> u64, u16 {
    let ticks = ((id.b[6] & 0x0f) as u64) << 56
        | (id.b[7] as u64) << 48
        | (id.b[4] as u64) << 40
        | (id.b[5] as u64) << 32
        | (id.b[0] as u64) << 24
        | (id.b[1] as u64) << 16
        | (id.b[2] as u64) << 8
        | id.b[3];
    let counter = ((id.b[8] & 0x3f) as u16) << 8 | id.b[9];
    return ticks, counter;
}

fn ticks_v6(id: Id) -> u64, u16 {
    let ticks = (id.b[0] as u64) << 52
        | (id.b[1] as u64) << 44
        | (id.b[2] as u64) << 36
        | (id.b[3] as u64) << 28
        | (id.b[4] as u64) << 20
        | (id.b[5] as u64) << 12
        | ((id.b[6] & 0x0f) as u64) << 8
        | id.b[7];
    let counter = ((id.b[8] & 0x3f) as u16) << 8 | id.b[9];
    return ticks, counter;
}

fn time(id: Id) -> Time, bool {
    let ver = version(id);
    if ver == 1 || ver == 6 {
        var ticks: u64 = 0;
        var counter: u16 = 0;
        if ver == 1 { ticks, counter = ticks_v1(id); } else { ticks, counter = ticks_v6(id); }
        let seconds, nanos = ticks_to_unix(ticks);
        return Time { seconds: seconds, nanos: nanos, counter: counter, bits: 14 }, true;
    }
    if ver == 7 {
        var millis: u64 = 0;
        for i in 0..6 { millis = (millis << 8) | id.b[i]; }
        let nanos = ((millis % 1000) * 1000000) as! u32;
        return Time { seconds: millis / 1000, nanos: nanos, counter: 0, bits: 0 }, true;
    }
    return Time { seconds: 0, nanos: 0, counter: 0, bits: 0 }, false;
}

fn node(id: Id) -> u8[6], bool {
    var n: u8[6] = [0; 6];
    if version(id) != 1 && version(id) != 6 { return n, false; }
    for i in 0..6 { n[i] = id.b[10 + i]; }
    return n, true;
}

fn clock1(start: u16) -> Clock1 { Clock1 { n: start } }

fn clock1_next(c: Clock1&) -> u16 {
    let out = c.n & 0x3fff;
    c.n = c.n + 1;
    return out;
}

fn clock1_shared_next() -> u16 {
    if !shared_clock1_on {
        shared_clock1.n = random_seed() as! u16;
        shared_clock1_on = true;
    }
    return clock1_next(shared_clock1);
}

fn ::main() {
    print("goose tests/self_check.goose");
}
