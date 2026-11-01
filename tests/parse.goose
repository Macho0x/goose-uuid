// Text forms, nil and max, endian bytes, and the named namespaces.

import uuid from "..";

namespace parse;

fn self_check() -> bool {
    let dashed = "67e55044-10b1-426f-9247-bb680e5fe0c8";
    let id, ok = uuid::parse(dashed);
    if !ok || str(id) != dashed { return false; }
    let plain, pok = uuid::parse("67e5504410b1426f9247bb680e5fe0c8");
    if !pok || plain != id || uuid::simple(id) != "67e5504410b1426f9247bb680e5fe0c8" { return false; }
    let u, uok = uuid::parse("urn:uuid:67e55044-10b1-426f-9247-bb680e5fe0c8");
    let U, Uok = uuid::parse("URN:UUID:67e55044-10b1-426f-9247-bb680e5fe0c8");
    if !uok || !Uok || u != id || U != id { return false; }
    if uuid::urn(id) != "urn:uuid:67e55044-10b1-426f-9247-bb680e5fe0c8" { return false; }
    let braced, bok = uuid::parse("{67e55044-10b1-426f-9247-bb680e5fe0c8}");
    if !bok || braced != id || uuid::braced(id) != "{67e55044-10b1-426f-9247-bb680e5fe0c8}" { return false; }
    let bad, badok = uuid::parse("nope");
    if badok || !uuid::is_nil(bad) { return false; }

    if !uuid::is_nil(uuid::nil()) || uuid::is_nil(id) { return false; }
    if !uuid::is_max(uuid::max()) || str(uuid::max()) != "ffffffff-ffff-ffff-ffff-ffffffffffff" { return false; }

    var raw: u8[16] = [
        0xa1, 0xa2, 0xa3, 0xa4, 0xb1, 0xb2, 0xc1, 0xc2,
        0xd1, 0xd2, 0xd3, 0xd4, 0xd5, 0xd6, 0xd7, 0xd8,
    ];
    let le = uuid::from_bytes_le(raw);
    if str(le) != "a4a3a2a1-b2b1-c2c1-d1d2-d3d4d5d6d7d8" { return false; }
    let back = uuid::bytes_le(le);
    for i in 0..16 { if back[i] != raw[i] { return false; } }

    let fields = uuid::from_fields(0x67e55044, 0x10b1, 0x426f, [
        0x92, 0x47, 0xbb, 0x68, 0x0e, 0x5f, 0xe0, 0xc8,
    ]);
    if fields != id { return false; }
    let fields_le = uuid::from_fields_le(0xa1a2a3a4, 0xb1b2, 0xc1c2, [
        0xd1, 0xd2, 0xd3, 0xd4, 0xd5, 0xd6, 0xd7, 0xd8,
    ]);
    if str(fields_le) != "a4a3a2a1-b2b1-c2c1-d1d2-d3d4d5d6d7d8" { return false; }
    let hi, lo = uuid::u64_pair(id);
    if uuid::from_u64_pair(hi, lo) != id { return false; }

    if str(uuid::DNS) != "6ba7b810-9dad-11d1-80b4-00c04fd430c8" { return false; }
    if str(uuid::URL) != "6ba7b811-9dad-11d1-80b4-00c04fd430c8" { return false; }
    if str(uuid::OID) != "6ba7b812-9dad-11d1-80b4-00c04fd430c8" { return false; }
    if str(uuid::X500) != "6ba7b814-9dad-11d1-80b4-00c04fd430c8" { return false; }

    var ms_b: u8[16] = [0; 16];
    ms_b[8] = 0xc0;
    let ms = uuid::from_bytes(ms_b);
    if uuid::variant_kind(ms) != 2 || uuid::variant(ms) != 3 { return false; }
    let ncs = uuid::from_bytes([0; 16]);
    if uuid::variant_kind(ncs) != 0 { return false; }
    var fut_b: u8[16] = [0; 16];
    fut_b[8] = 0xe0;
    let fut = uuid::from_bytes(fut_b);
    if uuid::variant_kind(fut) != 3 { return false; }
    return true;
}

fn ::main() {
    if parse::self_check() { print("parse ok"); } else { print("parse FAIL"); exit(1); }
}
