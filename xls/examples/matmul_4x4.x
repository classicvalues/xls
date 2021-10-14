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

// DSLX implementation of a 4x4 systolic array, appropriate for part of a
// matrix multiplier.

// TODO(rspringer): 2021-09-16, issue #497: The channel declarations here are a
// bit unwieldy; if we can use arrays-of-channels, that'll make things cleaner.

// TODO(rspringer): 2021-09-14: There seems to be an issue constexpr-evaluating
// F32 values, so for now we'll use u32s for our values, but this will change
// very soon.

// "node" performs the actual work of this systolic array, multiplying an input
// activation by the baked-in weight.
proc node {
  from_west: chan in u32;
  from_north: chan in u32;
  to_east: chan in u32;
  to_south: chan in u32;
  weight: u32;

  config(from_west: chan in u32, from_north: chan in u32,
         to_east: chan out u32, to_south: chan out u32, weight: u32) {
    (from_west, from_north, to_east, to_south, weight)
  }

  next() {
    let activation = recv(from_west);
    let partial_sum = recv(from_north);

    // Compute our partial product.
    let product = activation * weight;

    // Send the activation east and the partial product south.
    send(to_east, activation);
    send(to_south, product);
    ()
  }
}

// "driver" drives the computation in the array, "inserting" values into the
// west and north sides of the network and collecting output values.
proc driver {
  east_to_00: chan out u32;
  east_to_10: chan out u32;
  east_to_20: chan out u32;
  east_to_30: chan out u32;

  south_to_00: chan out u32;
  south_to_01: chan out u32;
  south_to_02: chan out u32;
  south_to_03: chan out u32;

  out_04: chan in u32;
  out_14: chan in u32;
  out_24: chan in u32;
  out_34: chan in u32;

  out_40: chan in u32;
  out_41: chan in u32;
  out_42: chan in u32;
  out_43: chan in u32;

  config(
    east_to_00: chan out u32, east_to_10: chan out u32,
    east_to_20: chan out u32, east_to_30: chan out u32,
    south_to_00: chan out u32, south_to_01: chan out u32,
    south_to_02: chan out u32, south_to_03: chan out u32,
    out_04: chan in u32, out_14: chan in u32, out_24: chan in u32, out_34: chan in u32,
    out_40: chan in u32, out_41: chan in u32, out_42: chan in u32, out_43: chan in u32) {
    (east_to_00, east_to_10, east_to_20, east_to_30,
     south_to_00, south_to_01, south_to_02, south_to_03,
     out_04, out_14, out_24, out_34, out_40, out_41, out_42, out_43)
  }

  // Pass the result as a state parameter so that the proc evaluators print it.
  next(basis: u32, result_0: u32, result_1: u32, result_2: u32, result_3: u32) {
    send(east_to_00, basis);
    send(east_to_10, basis);
    send(east_to_20, basis);
    send(east_to_30, basis);

    send(south_to_00, u32:0);
    send(south_to_01, u32:0);
    send(south_to_02, u32:0);
    send(south_to_03, u32:0);

    let _ = recv(out_04);
    let _ = recv(out_14);
    let _ = recv(out_24);
    let _ = recv(out_34);
    let result_0 = recv(out_40);
    let result_1 = recv(out_41);
    let result_2 = recv(out_42);
    let result_3 = recv(out_43);

    let basis = basis * u32:2;
    (basis, result_0, result_1, result_2, result_3)
  }

}

proc main {
  config() {
    // Declare the east-to-west channels.
    let (main_west_input0, cell_00_west_in) = chan u32;
    let (main_west_input1, cell_10_west_in) = chan u32;
    let (main_west_input2, cell_20_west_in) = chan u32;
    let (main_west_input3, cell_30_west_in) = chan u32;

    let (cell_00_east_out, cell_01_west_in) = chan u32;
    let (cell_01_east_out, cell_02_west_in) = chan u32;
    let (cell_02_east_out, cell_03_west_in) = chan u32;
    let (cell_03_east_out, cell_04_west_in) = chan u32;

    let (cell_10_east_out, cell_11_west_in) = chan u32;
    let (cell_11_east_out, cell_12_west_in) = chan u32;
    let (cell_12_east_out, cell_13_west_in) = chan u32;
    let (cell_13_east_out, cell_14_west_in) = chan u32;

    let (cell_20_east_out, cell_21_west_in) = chan u32;
    let (cell_21_east_out, cell_22_west_in) = chan u32;
    let (cell_22_east_out, cell_23_west_in) = chan u32;
    let (cell_23_east_out, cell_24_west_in) = chan u32;

    let (cell_30_east_out, cell_31_west_in) = chan u32;
    let (cell_31_east_out, cell_32_west_in) = chan u32;
    let (cell_32_east_out, cell_33_west_in) = chan u32;
    let (cell_33_east_out, cell_34_west_in) = chan u32;

    // Declare the north-to-south channels
    let (main_south_input0, cell_00_north_in) = chan u32;
    let (main_south_input1, cell_01_north_in) = chan u32;
    let (main_south_input2, cell_02_north_in) = chan u32;
    let (main_south_input3, cell_03_north_in) = chan u32;

    let (cell_00_south_out, cell_10_north_in) = chan u32;
    let (cell_01_south_out, cell_11_north_in) = chan u32;
    let (cell_02_south_out, cell_12_north_in) = chan u32;
    let (cell_03_south_out, cell_13_north_in) = chan u32;

    let (cell_10_south_out, cell_20_north_in) = chan u32;
    let (cell_11_south_out, cell_21_north_in) = chan u32;
    let (cell_12_south_out, cell_22_north_in) = chan u32;
    let (cell_13_south_out, cell_23_north_in) = chan u32;

    let (cell_20_south_out, cell_30_north_in) = chan u32;
    let (cell_21_south_out, cell_31_north_in) = chan u32;
    let (cell_22_south_out, cell_32_north_in) = chan u32;
    let (cell_23_south_out, cell_33_north_in) = chan u32;

    let (cell_30_south_out, cell_40_north_in) = chan u32;
    let (cell_31_south_out, cell_41_north_in) = chan u32;
    let (cell_32_south_out, cell_42_north_in) = chan u32;
    let (cell_33_south_out, cell_43_north_in) = chan u32;

    // Spawn all the procs. Specify weights to give a "mul-by-two" matrix.
    spawn node(cell_00_west_in, cell_00_north_in, cell_00_east_out, cell_00_south_out, u32:2)();
    spawn node(cell_01_west_in, cell_01_north_in, cell_01_east_out, cell_01_south_out, u32:0)();
    spawn node(cell_02_west_in, cell_02_north_in, cell_02_east_out, cell_02_south_out, u32:0)();
    spawn node(cell_03_west_in, cell_03_north_in, cell_03_east_out, cell_03_south_out, u32:0)();

    spawn node(cell_10_west_in, cell_10_north_in, cell_10_east_out, cell_10_south_out, u32:0)();
    spawn node(cell_11_west_in, cell_11_north_in, cell_11_east_out, cell_11_south_out, u32:2)();
    spawn node(cell_12_west_in, cell_12_north_in, cell_12_east_out, cell_12_south_out, u32:0)();
    spawn node(cell_13_west_in, cell_13_north_in, cell_13_east_out, cell_13_south_out, u32:0)();

    spawn node(cell_20_west_in, cell_20_north_in, cell_20_east_out, cell_20_south_out, u32:0)();
    spawn node(cell_21_west_in, cell_21_north_in, cell_21_east_out, cell_21_south_out, u32:0)();
    spawn node(cell_22_west_in, cell_22_north_in, cell_22_east_out, cell_22_south_out, u32:2)();
    spawn node(cell_23_west_in, cell_23_north_in, cell_23_east_out, cell_23_south_out, u32:0)();

    spawn node(cell_30_west_in, cell_30_north_in, cell_30_east_out, cell_30_south_out, u32:0)();
    spawn node(cell_31_west_in, cell_31_north_in, cell_31_east_out, cell_31_south_out, u32:0)();
    spawn node(cell_32_west_in, cell_32_north_in, cell_32_east_out, cell_32_south_out, u32:0)();
    spawn node(cell_33_west_in, cell_33_north_in, cell_33_east_out, cell_33_south_out, u32:2)();

    spawn driver(
        main_west_input0, main_west_input1, main_west_input2, main_west_input3,
        main_south_input0, main_south_input1, main_south_input2, main_south_input3,
        cell_04_west_in, cell_14_west_in, cell_24_west_in, cell_34_west_in,
        cell_40_north_in, cell_41_north_in, cell_42_north_in, cell_43_north_in)
        (u32:1, u32:0, u32:0, u32:0, u32:0);
    ()
  }

  next() { () }
}
