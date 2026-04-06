/**
 * @name Non-deterministic Random() calls
 * @description Multiple calls to functions that transitively call Random() in expressions with undefined evaluation order can lead to desyncs.
 * @kind problem
 * @problem.severity warning
 * @precision high
 * @id cpp/openttd/non-deterministic-random
 * @tags reliability
 *       maintainability
 *       network
 */

import cpp

/** A function that is known to use the synced random generator. */
class SyncedRandomFunction extends Function {
  SyncedRandomFunction() {
    this.hasGlobalName("Random") or
    this.hasGlobalName("RandomRange") or
    this.hasGlobalName("Chance16") or
    this.hasGlobalName("Chance16R")
  }
}

/** A function that transitively calls a synced random function. */
predicate callsSyncedRandom(Function f) {
  f.getACallee*() instanceof SyncedRandomFunction
}

/** An expression that transitively calls a synced random function. */
predicate exprCallsSyncedRandom(Expr e) {
  exists(FunctionCall call |
    call = e.getAChild*() and
    callsSyncedRandom(call.getTarget())
  )
}

from Expr parent, Expr child1, Expr child2
where
  (
    // Function arguments - evaluation order is unspecified until C++17,
    // and even then, interleaving is only partially restricted.
    exists(FunctionCall call |
      parent = call and
      child1 = call.getAnArgument() and
      child2 = call.getAnArgument() and
      child1 != child2
    )
    or
    // Binary operators (excluding those with defined order like &&, ||, , and ?:)
    exists(BinaryOperation op |
      parent = op and
      not op instanceof LogicalAndExpr and
      not op instanceof LogicalOrExpr and
      not op instanceof CommaExpr and
      child1 = op.getLeftOperand() and
      child2 = op.getRightOperand()
    )
  ) and
  exprCallsSyncedRandom(child1) and
  exprCallsSyncedRandom(child2)
select parent, "Potential desync: multiple operands/arguments in this expression transitively call Random(), but their evaluation order is undefined."
