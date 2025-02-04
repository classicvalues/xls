# Lint as: python3
#
# Copyright 2022 The XLS Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
"""Tests for xls.tools.codegen_main."""

import subprocess

from absl.testing import absltest
from xls.common import runfiles
from xls.common import test_base

BENCHMARK_CODEGEN_MAIN_PATH = runfiles.get_path(
    'xls/tools/benchmark_codegen_main')

SIMPLE_IR = """package add

top block my_block(clk: clock, a: bits[32], b: bits[32], out: bits[32]) {
  reg a_reg(bits[32])
  reg b_reg(bits[32])
  reg sum_reg(bits[32])

  a: bits[32] = input_port(name=a)
  a_d: () = register_write(a, register=a_reg)
  a_q: bits[32] = register_read(register=a_reg)

  b: bits[32] = input_port(name=b)
  b_d: () = register_write(b, register=b_reg)
  b_q: bits[32] = register_read(register=b_reg)

  sum: bits[32] = add(a_q, b_q)
  sum_d: () = register_write(sum, register=sum_reg)
  sum_q: bits[32] = register_read(register=sum_reg)

  not_sum_q: bits[32] = not(sum_q)
  not_not_sum_q: bits[32] = not(not_sum_q)

  out: () = output_port(not_not_sum_q, name=out)
}
"""

SIMPLE_VERILOG = """module main(
  input wire [31:0] x,
  output wire [31:0] out
);
  assign out = x;
endmodule
"""


class CodeGenMainTest(test_base.TestCase):

  def test_simple_block(self):
    ir_file = self.create_tempfile(content=SIMPLE_IR)
    verilog_file = self.create_tempfile(content=SIMPLE_VERILOG)
    output = subprocess.check_output([
        BENCHMARK_CODEGEN_MAIN_PATH, '--delay_model=unit', ir_file.full_path,
        verilog_file.full_path
    ]).decode('utf-8')

    self.assertIn('Flop count: 96', output)
    self.assertIn('Has feedthrough path: false', output)
    self.assertIn('Max reg-to-reg delay: 1ps', output)
    self.assertIn('Max input-to-reg delay: 0ps', output)
    self.assertIn('Max reg-to-output delay: 2ps', output)
    self.assertIn('Lines of Verilog: 7', output)

  def test_simple_block_no_delay_model(self):
    ir_file = self.create_tempfile(content=SIMPLE_IR)
    verilog_file = self.create_tempfile(content=SIMPLE_VERILOG)
    output = subprocess.check_output([
        BENCHMARK_CODEGEN_MAIN_PATH, ir_file.full_path,
        verilog_file.full_path
    ]).decode('utf-8')

    self.assertIn('Flop count: 96', output)
    self.assertIn('Has feedthrough path: false', output)
    self.assertNotIn('Max reg-to-reg delays', output)
    self.assertNotIn('Max input-to-reg delay', output)
    self.assertNotIn('Max reg-to-output delay', output)
    self.assertIn('Lines of Verilog: 7', output)


if __name__ == '__main__':
  absltest.main()
