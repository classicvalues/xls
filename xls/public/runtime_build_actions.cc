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

#include "xls/public/runtime_build_actions.h"

#include <filesystem>

#include "xls/dslx/import_data.h"
#include "xls/dslx/ir_converter.h"
#include "xls/dslx/parse_and_typecheck.h"
#include "xls/passes/passes.h"
#include "xls/tools/opt.h"

namespace xls {

absl::StatusOr<std::string> ConvertDslxToIr(
    absl::string_view dslx, absl::string_view path,
    absl::string_view module_name,
    absl::Span<const std::filesystem::path> additional_search_paths) {
  dslx::ImportData import_data;
  XLS_ASSIGN_OR_RETURN(
      dslx::TypecheckedModule typechecked,
      dslx::ParseAndTypecheck(dslx, path, module_name, &import_data,
                              additional_search_paths));
  return dslx::ConvertModule(typechecked.module, &import_data,
                             dslx::ConvertOptions{});
}

static absl::StatusOr<std::string> ExtractModuleName(
    std::filesystem::path path) {
  if (path.extension() != ".x") {
    return absl::InvalidArgumentError(
        absl::StrFormat("DSL module path must end with '.x', got: '%s'", path));
  }
  return path.stem();
}

absl::StatusOr<std::string> ConvertDslxPathToIr(
    std::filesystem::path path,
    absl::Span<const std::filesystem::path> additional_search_paths) {
  XLS_ASSIGN_OR_RETURN(std::string dslx, GetFileContents(path));
  XLS_ASSIGN_OR_RETURN(std::string module_name, ExtractModuleName(path));
  return ConvertDslxToIr(dslx, std::string(path), module_name,
                         additional_search_paths);
}

absl::StatusOr<std::string> OptimizeIr(absl::string_view ir,
                                       absl::string_view entry) {
  const tools::OptOptions options = {
      .opt_level = xls::kMaxOptLevel,
      .entry = entry,
  };
  return tools::OptimizeIrForEntry(ir, options);
}

}  // namespace xls
