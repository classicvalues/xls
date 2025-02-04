// Copyright 2021 The XLS Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
proc second_level_proc {
  input_c: chan in u32;
  output_p: chan out u32;

  config(input_c: chan in u32, output_p: chan out u32) {
    (input_c, output_p)
  }

  next(tok: token) { () }
}

proc first_level_proc {
  input_p0: chan out u32;
  input_p1: chan out u32;
  output_c0: chan in u32;
  output_c1: chan in u32;

  config() {
    let (input_p0, input_c0) = chan u32;
    let (output_p0, output_c0) = chan u32;
    spawn second_level_proc(input_c0, output_p0)();

    let (input_p1, input_c1) = chan u32;
    let (output_p1, output_c1) = chan u32;
    spawn second_level_proc(input_c1, output_p1)();

    (input_p0, input_p1, output_p0, output_p1)
  }

  next(tok: token) { () }
}

#![test_proc()]
proc tester {
  terminator: chan out bool;
  config(terminator: chan out bool) {
    spawn first_level_proc()();
    (terminator,)
  }

  next(tok: token) {
    let tok = send(tok, terminator, true);
    ()
  }
}
