// Version 8 keeps the caller's bytes except the version and variant fields.

import uuid from "..";
import uuid.uuid8;

namespace uuid8;

fn self_check() -> bool {
    let id = new([
        0x0f, 0x0e, 0x0d, 0x0c, 0x0b, 0x0a, 0x09, 0x08,
        0x07, 0x06, 0x05, 0x04, 0x03, 0x02, 0x01, 0x00,
    ]);
    if str(id) != "0f0e0d0c-0b0a-8908-8706-050403020100" { return false; }
    if uuid::version(id) != 8 || uuid::variant(id) != 2 { return false; }
    return true;
}

fn ::main() {
    if uuid8::self_check() { print("uuid8 ok"); } else { print("uuid8 FAIL"); exit(1); }
}
