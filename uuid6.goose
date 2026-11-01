// UUID version 6 (RFC 9562 §5.6). The version 1 timestamp, stored so the
// bytes sort by time. now shares the clock sequence with version 1.

import std;
import os;
import uuid;

namespace uuid6;

fn from_ticks(ticks: u64, counter: u16, node: u8[:]) -> uuid::Id, bool {
    return uuid::v6(ticks, counter, node);
}

fn from_unix(seconds: u64, nanos: u32, counter: u16, node: u8[:]) -> uuid::Id, bool {
    return uuid::v6(uuid::unix_to_ticks(seconds, nanos), counter, node);
}

fn from_ns(ns: i64, counter: u16, node: u8[:]) -> uuid::Id, bool {
    if ns < 0 { return uuid::nil(), false; }
    let seconds = (ns / 1000000000) as u64;
    let nanos = (ns % 1000000000) as! u32;
    return from_unix(seconds, nanos, counter, node);
}

fn now(node: u8[:]) -> uuid::Id, bool {
    return from_ns(time_ns(), uuid::clock1_shared_next(), node);
}
