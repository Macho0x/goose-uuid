<p align="center">
  <img src="logo.png" alt="A goose wearing an ID badge" width="220">
</p>

<h1 align="center">goose-uuid</h1>

<p align="center">
  🪪 UUIDs for <a href="https://github.com/aardappel/goose">Goose</a><br>
  <strong>0.3</strong> · <a href="LICENSE">Apache-2.0</a>
</p>

UUIDs as specified by [RFC 9562](https://www.rfc-editor.org/rfc/rfc9562). Versions 1, 3, 4, 5, 6, 7, and 8, the nil and max values, and the four text forms.

The default text is 36 characters, `8-4-4-4-12`, lowercase. `parse` also accepts 32 hex digits, `{8-4-4-4-12}`, and `urn:uuid:`, in either hex case. The URN prefix is case-insensitive.

## Example

```goose
import uuid from "../uuid";
import uuid.uuid4;
import uuid.uuid7;

fn main() {
    let a = uuid4::new();
    let b = uuid7::new();
    print(a);
    print(b);
}
```

`uuid.goose` is the 16-byte value, the text forms, and the shared helpers. Importing the package does not pull in a version. `import uuid.uuid7` does.

## Check

Install the Goose compiler, then from this directory:

```sh
goose tests/self_check.goose
```

A good run prints `uuid ok`. Each file in `tests/` can also be run on its own.

## Modules

| Module | What it does |
| --- | --- |
| `uuid` | 16 bytes, text, nil and max, namespaces, endian fields, and the version 1 and 6 timestamp layout |
| `uuid1` | Version 1 from Gregorian 100ns ticks, a 14-bit clock sequence, and a 6-byte node |
| `uuid3` | Version 3, MD5 of a namespace UUID and a name |
| `uuid4` | Version 4 from 16 random bytes, or from `os.random_seed` |
| `uuid5` | Version 5, the first 16 bytes of SHA-1 over a namespace UUID and a name |
| `uuid6` | Version 6, the version 1 timestamp stored so the bytes sort by time |
| `uuid7` | Version 7 from a Unix millisecond timestamp. `new` keeps a monotonic counter |
| `uuid8` | Version 8 from 16 caller-supplied bytes |

## Good to know

`uuid4::new` and the random fill inside `uuid7::new` read `/dev/urandom` through `os.random_seed` on Linux. On Windows the Goose runtime mixes clocks, which is not a CSPRNG.

`uuid1::now` and `uuid6::now` share one 14-bit clock sequence. It starts from `os.random_seed` and wraps. `uuid7::new` keeps a 42-bit counter that reseeds when the millisecond changes, keeps the last timestamp if the clock steps backward, and moves the timestamp forward if the counter runs out. `uuid7::from_millis` writes an explicit 10-byte block, with `rand_a` in the first two bytes and `rand_b` in the rest.

`uuid7::context`, `adjust_by_millis`, and `set_precision` configure that counter. Precision bits are capped at 12 and occupy the high bits of the counter. A 128-bit value is two `u64` halves, via `uuid::from_u64_pair`. Goose threads do not share memory, so the counters are process-local.

## License

Apache-2.0. Free and open to everyone. The terms are in [LICENSE](LICENSE).
