// Version 6 timestamp vectors.

import uuid from "..";
import uuid.uuid6;

namespace uuid6;

fn node() -> u8[6] { [1, 2, 3, 4, 5, 6] }

fn self_check() -> bool {
    let a, aok = from_unix(1496854535, 812946000, 0, node());
    if !aok || str(a) != "1e74ba22-0616-6934-8000-010203040506" { return false; }
    let b, bok = from_unix(1497624119, 1234, 42, node());
    if !bok || str(b) != "1e752a1f-3b49-658c-802a-010203040506" { return false; }
    let c, cok = from_ticks(14976241191231231313, 42, node());
    if !cok || str(c) != "fd64c041-1e91-6551-802a-010203040506" { return false; }
    let early, early_ok = from_ns(-1, 0, node());
    if early_ok || !uuid::is_nil(early) { return false; }
    let short, short_ok = from_ticks(1, 0, []);
    if short_ok || !uuid::is_nil(short) { return false; }
    let ta, aok = uuid::time(a);
    if !aok || ta.seconds != 1496854535 || ta.nanos != 812946000 { return false; }
    let n, nok = uuid::node(b);
    if !nok || n != node() { return false; }
    for i in 0..16 {
        if a.b[i] < b.b[i] { break; }
        if a.b[i] > b.b[i] { return false; }
    }
    return true;
}

fn ::main() {
    if uuid6::self_check() { print("uuid6 ok"); } else { print("uuid6 FAIL"); exit(1); }
}
