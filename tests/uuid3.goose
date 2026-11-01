// Version 3 fixtures: MD5(namespace || name), then version and variant bits.

import uuid from "..";
import uuid.uuid3;

namespace uuid3;

fn one(ns: uuid::Id, name: u8[:], want: u8[:]) -> bool {
    let id = new(ns, name);
    if str(id) != want { return false; }
    if uuid::version(id) != 3 || uuid::variant(id) != 2 { return false; }
    return true;
}

fn self_check() -> bool {
    if !one(uuid::DNS, "example.org", "04738bdf-b25a-3829-a801-b21a1d25095b") { return false; }
    if !one(uuid::DNS, "goose-lang.org", "74d80cef-d2a7-391e-ae92-f2625ca6268f") { return false; }
    if !one(uuid::DNS, "42", "5aab6e0c-b7d3-379c-92e3-2bfbb5572511") { return false; }
    if !one(uuid::DNS, "lorem ipsum", "4f8772e9-b59c-3cc9-91a9-5c823df27281") { return false; }
    if !one(uuid::URL, "example.org", "39682ca1-9168-3da2-a1bb-f4dbcde99bf9") { return false; }
    if !one(uuid::URL, "goose-lang.org", "1bc10183-f031-33c7-8922-6a63f9373c87") { return false; }
    if !one(uuid::URL, "42", "08998a0c-fcf4-34a9-b444-f2bfc15731dc") { return false; }
    if !one(uuid::URL, "lorem ipsum", "e55ad2e6-fb89-34e8-b012-c5dde3cd67f0") { return false; }
    if !one(uuid::OID, "example.org", "f14eec63-2812-3110-ad06-1625e5a4a5b2") { return false; }
    if !one(uuid::OID, "goose-lang.org", "2134f798-a1c6-365c-b1b7-4cd0b1e8ca2c") { return false; }
    if !one(uuid::OID, "42", "ce6925a5-2cd7-327b-ab1c-4b375ac044e4") { return false; }
    if !one(uuid::OID, "lorem ipsum", "5dd8654f-76ba-3d47-bc2e-4d6d3a78cb09") { return false; }
    if !one(uuid::X500, "example.org", "64606f3f-bd63-363e-b946-fca13611b6f7") { return false; }
    if !one(uuid::X500, "goose-lang.org", "e33bce20-f1c2-3fa2-8cd2-6f8f80c7d559") { return false; }
    if !one(uuid::X500, "42", "c1073fa2-d4a6-3104-b21d-7a6bdcf39a23") { return false; }
    if !one(uuid::X500, "lorem ipsum", "02f09a3f-1624-3b1d-8409-44eff7708208") { return false; }
    return true;
}

fn ::main() {
    if uuid3::self_check() { print("uuid3 ok"); } else { print("uuid3 FAIL"); exit(1); }
}
