// Version 1 timestamp vectors.

import uuid from "..";
import uuid.uuid1;
import os;

namespace uuid1;

fn node() -> u8[6] { [1, 2, 3, 4, 5, 6] }

fn self_check() -> bool {
    let a, aok = from_unix(1496854535, 812946000, 0, node());
    if !aok || str(a) != "20616934-4ba2-11e7-8000-010203040506" { return false; }
    let b, bok = from_unix(1497624119, 1234, 42, node());
    if !bok || str(b) != "f3b4958c-52a1-11e7-802a-010203040506" { return false; }
    let c, cok = from_ticks(14976234442241191232, 42, node());
    if !cok || str(c) != "b2c1ad40-45e0-1fd6-802a-010203040506" { return false; }
    let early, early_ok = from_ns(-1, 0, node());
    if early_ok || !uuid::is_nil(early) { return false; }
    let short, short_ok = from_ticks(1, 0, []);
    if short_ok || !uuid::is_nil(short) { return false; }

    let ta, aok = uuid::time(a);
    if !aok || ta.seconds != 1496854535 || ta.nanos != 812946000 || ta.counter != 0 { return false; }
    let tb, bok = uuid::time(b);
    if !bok || tb.seconds != 1497624119 || tb.nanos != 1200 || tb.counter != 42 { return false; }
    let n, nok = uuid::node(a);
    if !nok || n != node() { return false; }
    let none, noneok = uuid::node(uuid::nil());
    var zeros: u8[6] = [0; 6];
    if noneok || none != zeros { return false; }

    var clock = uuid::clock1(0x3fff);
    if uuid::clock1_next(clock) != 16383 || uuid::clock1_next(clock) != 0 { return false; }

    let ns = time_ns();
    if ns >= 0 {
        let made, mok = now(node());
        if !mok || uuid::version(made) != 1 || uuid::variant(made) != 2 { return false; }
        let tm, tok = uuid::time(made);
        if !tok { return false; }
        let got = tm.seconds * 1000000000 + tm.nanos;
        let clock = ns as u64;
        if got + 1000000000 < clock || got > clock + 1000000000 { return false; }
    }
    return true;
}

fn ::main() {
    if uuid1::self_check() { print("uuid1 ok"); } else { print("uuid1 FAIL"); exit(1); }
}
