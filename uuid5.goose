// UUID version 5 (RFC 9562 §5.5). The first 16 bytes of SHA-1 over a
// namespace UUID and a name.

import std;
import uuid;
import sha1;

namespace uuid5;

fn new(ns: uuid::Id, name: u8[:]) -> uuid::Id {
    var id = uuid::Id { b: sha1::hash(ns.b, name) };
    uuid::stamp(id, 5);
    return id;
}
