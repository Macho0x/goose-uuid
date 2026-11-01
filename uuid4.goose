// UUID version 4 (RFC 9562 §5.4). Sixteen random bytes, then the version
// nibble is 4 and the variant bits are 10.

import std;
import uuid;

namespace uuid4;

fn from_random(rand: u8[:]) -> uuid::Id {
    if rand.len != 16 { abort("uuid4: random data must be 16 bytes"); }
    var id = uuid::from_bytes(rand);
    uuid::stamp(id, 4);
    return id;
}

fn new() -> uuid::Id {
    var raw: u8[16] = [0; 16];
    uuid::random_bytes(raw);
    return from_random(raw);
}

fn parse(s: u8[:]) -> uuid::Id, bool {
    let id, ok = uuid::parse(s);
    if !ok || uuid::version(id) != 4 || uuid::variant(id) != 2 {
        return uuid::Id { b: [0; 16] }, false;
    }
    return id, true;
}
