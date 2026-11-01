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
    if !one(uuid::DNS, "rust-lang.org", "c6db027c-615c-3b4d-959e-1a917747ca5a") { return false; }
    if !one(uuid::DNS, "42", "5aab6e0c-b7d3-379c-92e3-2bfbb5572511") { return false; }
    if !one(uuid::DNS, "lorem ipsum", "4f8772e9-b59c-3cc9-91a9-5c823df27281") { return false; }
    if !one(uuid::URL, "example.org", "39682ca1-9168-3da2-a1bb-f4dbcde99bf9") { return false; }
    if !one(uuid::URL, "rust-lang.org", "7ed45aaf-e75b-3130-8e33-ee4d9253b19f") { return false; }
    if !one(uuid::URL, "42", "08998a0c-fcf4-34a9-b444-f2bfc15731dc") { return false; }
    if !one(uuid::URL, "lorem ipsum", "e55ad2e6-fb89-34e8-b012-c5dde3cd67f0") { return false; }
    if !one(uuid::OID, "example.org", "f14eec63-2812-3110-ad06-1625e5a4a5b2") { return false; }
    if !one(uuid::OID, "rust-lang.org", "6506a0ec-4d79-3e18-8c2b-f2b6b34f2b6d") { return false; }
    if !one(uuid::OID, "42", "ce6925a5-2cd7-327b-ab1c-4b375ac044e4") { return false; }
    if !one(uuid::OID, "lorem ipsum", "5dd8654f-76ba-3d47-bc2e-4d6d3a78cb09") { return false; }
    if !one(uuid::X500, "example.org", "64606f3f-bd63-363e-b946-fca13611b6f7") { return false; }
    if !one(uuid::X500, "rust-lang.org", "bcee7a9c-52f1-30c6-a3cc-8c72ba634990") { return false; }
    if !one(uuid::X500, "42", "c1073fa2-d4a6-3104-b21d-7a6bdcf39a23") { return false; }
    if !one(uuid::X500, "lorem ipsum", "02f09a3f-1624-3b1d-8409-44eff7708208") { return false; }
    return true;
}

fn ::main() {
    if uuid3::self_check() { print("uuid3 ok"); } else { print("uuid3 FAIL"); exit(1); }
}
