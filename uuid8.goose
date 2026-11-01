// UUID version 8 (RFC 9562 §5.8). The 16 bytes are the caller's, with the
// version nibble set to 8 and the variant bits set to 10.

import std;
import uuid;

namespace uuid8;

fn new(b: u8[:]) -> uuid::Id, bool {
    let id, ok = uuid::from_bytes(b);
    if !ok { return uuid::nil(), false; }
    uuid::stamp(id, 8);
    return id, true;
}
