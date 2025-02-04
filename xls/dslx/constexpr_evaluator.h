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
#ifndef XLS_DSLX_CONSTEXPR_EVALUATOR_H_
#define XLS_DSLX_CONSTEXPR_EVALUATOR_H_

#include "absl/status/status.h"
#include "xls/dslx/ast.h"
#include "xls/dslx/deduce_ctx.h"

namespace xls::dslx {

// Simple visitor to perform automatic dispatch to constexpr evaluate AST
// expressions.
// TODO(rspringer): 2021-10-15, issue #508: Not all expression nodes are
// currently covered, but will need to be shortly.
class ConstexprEvaluator : public xls::dslx::ExprVisitor {
 public:
  // A concrete type is only necessary when:
  //  - Deducing a Number that is undecorated and whose type is specified by
  //    context, e.g., an element in a constant array:
  //    `u32[4]:[0, 1, 2, 3]`. It can be nullptr in all other circumstances.
  //  - Deducing a constant array whose declaration terminates in an ellipsis:
  //    `u32[4]:[0, 1, ...]`. The type is needed to determine the number of
  //    elements to fill in.
  // In all other cases, `concrete_type` can be nullptr.
  ConstexprEvaluator(DeduceCtx* ctx, const ConcreteType* concrete_type)
      : ctx_(ctx), concrete_type_(concrete_type) {}
  ~ConstexprEvaluator() override {}

  void HandleJoin(Join* expr) override {}
  void HandleArray(Array* expr) override;
  void HandleAttr(Attr* expr) override;
  void HandleBinop(Binop* expr) override;
  void HandleCast(Cast* expr) override;
  void HandleChannelDecl(ChannelDecl* expr) override {}
  void HandleColonRef(ColonRef* expr) override;
  void HandleConstRef(ConstRef* expr) override;
  void HandleFor(For* expr) override {}
  void HandleFormatMacro(FormatMacro* expr) override {}
  void HandleIndex(Index* expr) override;
  void HandleInvocation(Invocation* expr) override;
  void HandleLet(Let* expr) override {}
  void HandleMatch(Match* expr) override {}
  void HandleNameRef(NameRef* expr) override;
  void HandleNumber(Number* expr) override;
  void HandleRecv(Recv* expr) override {}
  void HandleRecvIf(RecvIf* expr) override {}
  void HandleSend(Send* expr) override {}
  void HandleSendIf(SendIf* expr) override {}
  void HandleSpawn(Spawn* expr) override {}
  void HandleString(String* expr) override {}
  void HandleStructInstance(StructInstance* expr) override;
  void HandleSplatStructInstance(SplatStructInstance* expr) override {}
  void HandleTernary(Ternary* expr) override;
  void HandleUnop(Unop* expr) override {}
  void HandleXlsTuple(XlsTuple* expr) override;

  absl::Status status() { return status_; }

 private:
  bool IsConstExpr(const Expr* expr);
  absl::Status SimpleEvaluate(Expr* expr);

  DeduceCtx* ctx_;
  const ConcreteType* concrete_type_;
  absl::Status status_;
};

}  // namespace xls::dslx

#endif  // XLS_DSLX_CONSTEXPR_EVALUATOR_H_
