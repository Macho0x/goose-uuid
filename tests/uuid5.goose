// Version 5 fixtures: the first 16 bytes of SHA-1(namespace || name).

import uuid from "..";
import uuid.uuid5;

namespace uuid5;

fn one(ns: uuid::Id, name: u8[:], want: u8[:]) -> bool {
    let id = new(ns, name);
    if str(id) != want { return false; }
    if uuid::version(id) != 5 || uuid::variant(id) != 2 { return false; }
    return true;
}

fn self_check() -> bool {
    if !one(uuid::DNS, "example.org", "aad03681-8b63-5304-89e0-8ca8f49461b5") { return false; }
    if !one(uuid::DNS, "goose-lang.org", "23266abf-196a-5436-8db0-f8ee90410345") { return false; }
    if !one(uuid::DNS, "42", "7c411b5e-9d3f-50b5-9c28-62096e41c4ed") { return false; }
    if !one(uuid::DNS, "lorem ipsum", "97886a05-8a68-5743-ad55-56ab2d61cf7b") { return false; }
    if !one(uuid::URL, "example.org", "54a35416-963c-5dd6-a1e2-5ab7bb5bafc7") { return false; }
    if !one(uuid::URL, "goose-lang.org", "ac22c370-41a1-53d8-b373-6bf77d51a8a6") { return false; }
    if !one(uuid::URL, "42", "5c2b23de-4bad-58ee-a4b3-f22f3b9cfd7d") { return false; }
    if !one(uuid::URL, "lorem ipsum", "15c67689-4b85-5253-86b4-49fbb138569f") { return false; }
    if !one(uuid::OID, "example.org", "34784df9-b065-5094-92c7-00bb3da97a30") { return false; }
    if !one(uuid::OID, "goose-lang.org", "c9342975-d6d5-53a9-ad5b-c4ec27ada8d3") { return false; }
    if !one(uuid::OID, "42", "ba293c61-ad33-57b9-9671-f3319f57d789") { return false; }
    if !one(uuid::OID, "lorem ipsum", "6485290d-f79e-5380-9e64-cb4312c7b4a6") { return false; }
    if !one(uuid::X500, "example.org", "e3635e86-f82b-5bbc-a54a-da97923e5c76") { return false; }
    if !one(uuid::X500, "goose-lang.org", "72c1817c-c408-5beb-8ec6-70e798c1bc87") { return false; }
    if !one(uuid::X500, "42", "e4b88014-47c6-5fe0-a195-13710e5f6e27") { return false; }
    if !one(uuid::X500, "lorem ipsum", "b11f79a5-1e6d-57ce-a4b5-ba8531ea03d0") { return false; }
    return true;
}

fn ::main() {
    if uuid5::self_check() { print("uuid5 ok"); } else { print("uuid5 FAIL"); exit(1); }
}
