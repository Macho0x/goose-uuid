import uuid from "..";
import uuid.uuid4;

namespace uuid4;

fn is(id: uuid::Id, text: u8[:]) -> bool {
    let back, ok = parse(text);
    return ok && back == id && str(id) == text;
}

fn zero() -> uuid::Id { uuid::Id { b: [0; 16] } }

fn rejected(s: u8[:]) -> bool {
    let id, ok = uuid::parse(s);
    return !ok && id == zero();
}

fn self_check() -> bool {
    // RFC 9562 appendix A.3. The random block is the one before version and variant are set.
    var raw: u8[16] = [
        0x91, 0x91, 0x08, 0xf7, 0x52, 0xd1, 0x33, 0x20,
        0x5b, 0xac, 0xf8, 0x47, 0xdb, 0x41, 0x48, 0xa8,
    ];
    let id = from_random(raw);
    if !is(id, "919108f7-52d1-4320-9bac-f847db4148a8") { return false; }
    if uuid::version(id) != 4 || uuid::variant(id) != 2 { return false; }
    for i in 0..16 {
        if i == 6 || i == 8 { continue; }
        if id.b[i] != raw[i] { return false; }
    }
    if id.b[6] != 0x43 || id.b[8] != 0x9b { return false; }
    let up, up_ok = parse("919108F7-52D1-4320-9BAC-F847DB4148A8");
    if !up_ok || up != id { return false; }

    var z: u8[16] = [0; 16];
    if !is(from_random(z), "00000000-0000-4000-8000-000000000000") { return false; }
    var f: u8[16] = [0xff; 16];
    if !is(from_random(f), "ffffffff-ffff-4fff-bfff-ffffffffffff") { return false; }

    if !rejected("") { return false; }
    if !rejected("919108f7-52d1-4320-9bac-f847db4148a") { return false; }
    if !rejected("919108f7-52d1-4320-9bac-f847db4148a8f") { return false; }
    if !rejected("919108f7-52d1-4320-9bac-f847db4148ag") { return false; }
    if !rejected("919108f7052d1-4320-9bac-f847db4148a8") { return false; }

    // Figure 21, before the version and variant bits are overwritten.
    let swapped, sok = parse("919108f7-52d1-3320-5bac-f847db4148a8");
    if sok || swapped != zero() { return false; }
    let other, ook = uuid::parse("919108f7-52d1-3320-5bac-f847db4148a8");
    if !ook || uuid::version(other) != 3 || uuid::variant(other) != 1 { return false; }
    let v7, v7ok = parse("017f22e2-79b0-7cc3-98c4-dc0c0c07398f");
    if v7ok || v7 != zero() { return false; }

    let made = new();
    if uuid::version(made) != 4 || uuid::variant(made) != 2 { return false; }
    let back, bok = parse(str(made));
    if !bok || back != made { return false; }
    return true;
}

fn ::main() {
    if uuid4::self_check() { print("uuid4 ok"); } else { print("uuid4 FAIL"); exit(1); }
}
