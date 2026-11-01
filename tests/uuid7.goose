import uuid from "..";
import uuid.uuid7;
import os;

namespace uuid7;

fn is(id: uuid::Id, text: u8[:]) -> bool {
    let back, ok = parse(text);
    return ok && back == id && str(id) == text;
}

fn before(a: u8[:], b: u8[:]) -> bool {
    let n = if a.len < b.len { a.len } else { b.len };
    for i in 0..n {
        if a[i] < b[i] { return true; }
        if a[i] > b[i] { return false; }
    }
    return a.len < b.len;
}

fn self_check() -> bool {
    // RFC 9562 appendix A.6. Tuesday, February 22, 2022 2:22:22.00 PM GMT-05:00.
    var rand: u8[10] = [0x0c, 0xc3, 0x18, 0xc4, 0xdc, 0x0c, 0x0c, 0x07, 0x39, 0x8f];
    let id = from_millis(0x017F22E279B0, rand);
    if !is(id, "017f22e2-79b0-7cc3-98c4-dc0c0c07398f") { return false; }
    if unix_ms(id) != 0x017F22E279B0 || unix_ms(id) != 1645557742000 { return false; }
    let tm, tok = uuid::time(id);
    if !tok || tm.seconds != 1645557742 || tm.nanos != 0 || tm.counter != 0 { return false; }
    var junk: u8[10] = [0xac, 0xc3, 0xd8, 0xc4, 0xdc, 0x0c, 0x0c, 0x07, 0x39, 0x8f];
    if from_millis(0x017F22E279B0, junk) != id { return false; }
    let up, up_ok = parse("017F22E2-79B0-7CC3-98C4-DC0C0C07398F");
    if !up_ok || up != id { return false; }

    var quiet: u8[10] = [0; 10];
    if !is(from_millis(0, quiet), "00000000-0000-7000-8000-000000000000") { return false; }
    if !is(from_millis(0xffffffffffff, quiet), "ffffffff-ffff-7000-8000-000000000000") { return false; }

    // A later millisecond sorts after, whatever the random bits are.
    var noisy: u8[10] = [0xff; 10];
    let early = from_millis(1000, noisy);
    let later = from_millis(1001, quiet);
    let early_s = str(early);
    let later_s = str(later);
    if !before(early.b, later.b) || !before(early_s, later_s) { return false; }

    // The same millisecond follows rand_a, then rand_b.
    var lo: u8[10] = [0; 10];
    var hi: u8[10] = [0; 10];
    hi[1] = 1;
    let a = from_millis(1000, lo);
    let b = from_millis(1000, hi);
    let a_s = str(a);
    let b_s = str(b);
    if a == b || unix_ms(a) != 1000 || unix_ms(b) != 1000 { return false; }
    if !before(a.b, b.b) || !before(a_s, b_s) { return false; }

    let v4, v4ok = parse("919108f7-52d1-4320-9bac-f847db4148a8");
    let none = uuid::Id { b: [0; 16] };
    if v4ok || v4 != none { return false; }

    let t0 = time_ns() / 1000000;
    let made = new();
    let t1 = time_ns() / 1000000;
    if uuid::version(made) != 7 || uuid::variant(made) != 2 { return false; }
    let ms = unix_ms(made);
    if ms < t0 as u64 || ms > t1 as u64 { return false; }
    let back, bok = parse(str(made));
    if !bok || back != made { return false; }

    let zero = Wide { hi: 0, lo: 0 };
    let c1 = layout(1000, 1, 42, zero);
    let c2 = layout(1000, 2, 42, zero);
    if unix_ms(c1) != 1000 || !before(c1.b, c2.b) { return false; }
    var prev = made;
    for _n in 0..8 {
        let nxt = new();
        if unix_ms(nxt) < unix_ms(prev) { return false; }
        if unix_ms(nxt) == unix_ms(prev) && !before(prev.b, nxt.b) { return false; }
        prev = nxt;
    }
    return true;
}

fn ::main() {
    if uuid7::self_check() { print("uuid7 ok"); } else { print("uuid7 FAIL"); exit(1); }
}
