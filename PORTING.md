# Porting

A wrong length returns `false` and the nil UUID. A clock before the Unix epoch does the same, through `from_ns`. A version 7 timestamp past 48 bits does too. The MD5 and SHA-1 aborts stay: those are a message past the hash length.
