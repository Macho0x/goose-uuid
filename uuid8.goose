// UUID version 8 (RFC 9562 §5.8). The 16 bytes are the caller's, with the
// version nibble set to 8 and the variant bits set to 10.

import std;
import uuid;

namespace uuid8;

fn new(b: u8[:]) -> uuid::Id {
    if b.len != 16 { abort("uuid8: 16 bytes"); }
    var id = uuid::from_bytes(b);
    uuid::stamp(id, 8);
    return id;
}
