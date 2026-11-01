import uuid from "..";
import uuid.uuid4;
import .uuid4;
import uuid.uuid7;
import .uuid7;
import uuid.uuid1;
import .uuid1;
import uuid.uuid6;
import .uuid6;
import uuid.uuid8;
import .uuid8;
import uuid.uuid3;
import .uuid3;
import uuid.uuid5;
import .uuid5;
import .parse;
import os;

fn ::main() {
    if !uuid4::self_check() { fail("uuid4"); }
    if !uuid7::self_check() { fail("uuid7"); }
    if !uuid1::self_check() { fail("uuid1"); }
    if !uuid6::self_check() { fail("uuid6"); }
    if !uuid8::self_check() { fail("uuid8"); }
    if !uuid3::self_check() { fail("uuid3"); }
    if !uuid5::self_check() { fail("uuid5"); }
    if !parse::self_check() { fail("parse"); }
    write_stdout("uuid ok\n");
}

fn fail(name: u8[:]) {
    write_stdout(name);
    write_stdout(" FAIL\n");
    exit(1);
}
