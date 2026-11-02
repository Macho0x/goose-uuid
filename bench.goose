// Times this package. One untimed batch, then batches until the window
// elapses. The sink keeps the call alive.
// Build with clang on the revision before a change, then again after:
//   goose build -o uuid-bench bench.goose --cc clang
//   ./uuid-bench
// Row names stay fixed. TinyCC (goose bench.goose) is not a timing result.
// ponytail: a fixed window, not a sampled harness. Rows under a microsecond
// move from run to run; lengthen the window before trusting them.

import os;
import uuid;
import uuid4;
import uuid7;

const dashed: u8[:] = "00000000-0000-0000-0000-000000000000";
var raw: u8[16] = [0x11; 16];
var rand10: u8[10] = [0x22; 10];

fn mark(b: u8, ok: bool) -> u64 {
    if !ok { return 0; }
    let v: u64 = b;
    return v + 1;
}

fn time_batch<F>(batch: i64, ms: i64) -> i64, u64 {
    var sink: u64 = 0;
    var k = 0;
    while k < batch {
        sink += F();
        k += 1;
    }
    var n: i64 = 0;
    var dt: i64 = 0;
    let end = clock_ns() + ms * 1000000;
    while true {
        let t0 = clock_ns();
        k = 0;
        while k < batch {
            sink += F();
            k += 1;
        }
        dt += clock_ns() - t0;
        n += batch;
        if clock_ns() >= end { break; }
    }
    return dt / n, sink;
}

fn row<F>(name: u8[:], batch: i64, ms: i64) -> u64 {
    let ns, part = time_batch(batch, ms, F);
    var line: u8[>..] = [];
    format(line, name);
    while line.len < 28 { line.push(' '); }
    format_int(line, ns, 10, 12, ' ');
    format(line, "\n");
    write_stdout(line);
    return part;
}

fn fmt_row() -> u64 {
    raw[0] += 1;
    let id, ok = uuid::from_bytes(raw);
    if !ok { return 0; }
    var out: u8[>..] = [];
    uuid::format(out, id);
    if out.len != 36 { return 0; }
    return mark(out[0], true);
}

fn parse_row() -> u64 {
    let id, ok = uuid::parse(dashed);
    if !ok { return 0; }
    return mark(id.b[0], uuid::is_nil(id));
}

fn v4_row() -> u64 {
    raw[1] += 1;
    let id, ok = uuid4::from_random(raw);
    if !ok { return 0; }
    return mark(id.b[6], uuid::version(id) == 4);
}

fn v7_row() -> u64 {
    rand10[0] += 1;
    let id, ok = uuid7::from_millis(1700000000000, rand10);
    if !ok { return 0; }
    return mark(id.b[6], uuid::version(id) == 7);
}

fn ready() -> bool {
    var out: u8[>..] = [];
    uuid::format(out, uuid::nil());
    if out != dashed { return false; }
    let back, ok = uuid::parse(dashed);
    if !ok || !uuid::is_nil(back) { return false; }
    let a, aok = uuid4::from_random(raw);
    if !aok || uuid::version(a) != 4 { return false; }
    let b, bok = uuid7::from_millis(1, rand10);
    return bok && uuid::version(b) == 7;
}

fn ::main() {
    if !ready() { print("bench FAIL"); exit(1); }
    write_stdout("operation                       ns/call\n");
    var sink: u64 = 0;
    sink += row("format", 64, 200, fmt_row);
    sink += row("parse nil", 64, 200, parse_row);
    sink += row("uuid4 from_random", 64, 200, v4_row);
    sink += row("uuid7 from_millis", 64, 200, v7_row);
    var tail: u8[>..] = [];
    format(tail, "sink ");
    format(tail, sink);
    format(tail, "\n");
    write_stdout(tail);
}
