// UUID version 3 (RFC 9562 §5.3). MD5 of a namespace UUID and a name.

import std;
import uuid;
import md5;

namespace uuid3;

fn new(ns: uuid::Id, name: u8[:]) -> uuid::Id {
    var id = uuid::Id { b: md5::hash(ns.b, name) };
    uuid::stamp(id, 3);
    return id;
}
