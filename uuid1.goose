// UUID version 1 (RFC 9562 §5.1). Gregorian 100ns ticks, a 14-bit clock
// sequence, and a 6-byte node. now shares the clock sequence with version 6.

import std;
import os;
import uuid;

namespace uuid1;

fn from_ticks(ticks: u64, counter: u16, node: u8[:]) -> uuid::Id {
    return uuid::v1(ticks, counter, node);
}

fn from_unix(seconds: u64, nanos: u32, counter: u16, node: u8[:]) -> uuid::Id {
    return uuid::v1(uuid::unix_to_ticks(seconds, nanos), counter, node);
}

fn now(node: u8[:]) -> uuid::Id {
    let ns = time_ns();
    if ns < 0 { abort("uuid1: clock is before the Unix epoch"); }
    let seconds = (ns / 1000000000) as u64;
    let nanos = (ns % 1000000000) as! u32;
    return from_unix(seconds, nanos, uuid::clock1_shared_next(), node);
}
