/**
 * @name Tracked calls in undefined-order callsites
 * @description Finds undefined-order callsites where at least two sibling arguments (or both binary operands) contain tracked calls such as Random(), RandomRange(), or guarded calls.
 * @kind problem
 * @problem.severity warning
 * @id cpp/openttd/random-in-undefined-order-callsite
 * @tags reliability
 *       correctness
 */

import cpp

predicate containsExpr(Expr container, Expr nested) {
	container = nested
	or
	nested = container.getAChild+()
}

class UnsequencedBinaryOperation extends BinaryOperation {
	UnsequencedBinaryOperation() {
		not this instanceof LogicalAndExpr and
		not this instanceof LogicalOrExpr
	}
}

class VehicleNextCall extends FunctionCall {
	VehicleNextCall() {
		exists(MemberFunction mf, Class declaring, Class vehicle |
			mf = this.getTarget() and
			mf.hasName("Next") and
			declaring = mf.getDeclaringType().(Class) and
			vehicle.hasName("Vehicle") and
			(
				declaring = vehicle
				or
				declaring.derivesFrom(vehicle)
			)
		)
	}
}

class RandomLikeCall extends FunctionCall {
	RandomLikeCall() {
		this.getTarget().hasGlobalName(["Random", "RandomRange"])
	}
}

class TrackedCall extends FunctionCall {
	TrackedCall() {
		this instanceof RandomLikeCall
		or
		this instanceof VehicleNextCall
	}
}

predicate strictlySequencedOrNotBothEvaluated(TrackedCall c1, TrackedCall c2) {
	containsExpr(c1, c2)
	or
	containsExpr(c2, c1)
	or
	exists(AggregateLiteral al |
		containsExpr(al, c1) and
		containsExpr(al, c2)
	)
	or
	exists(ParenthesizedBracedInitializerList bl |
		containsExpr(bl, c1) and
		containsExpr(bl, c2)
	)
	or
	exists(CommaExpr comma |
		(
			containsExpr(comma.getLeftOperand(), c1) and
			containsExpr(comma.getRightOperand(), c2)
		)
		or
		(
			containsExpr(comma.getLeftOperand(), c2) and
			containsExpr(comma.getRightOperand(), c1)
		)
	)
	or
	exists(LogicalAndExpr op |
		(
			containsExpr(op.getLeftOperand(), c1) and
			containsExpr(op.getRightOperand(), c2)
		)
		or
		(
			containsExpr(op.getLeftOperand(), c2) and
			containsExpr(op.getRightOperand(), c1)
		)
	)
	or
	exists(LogicalOrExpr op |
		(
			containsExpr(op.getLeftOperand(), c1) and
			containsExpr(op.getRightOperand(), c2)
		)
		or
		(
			containsExpr(op.getLeftOperand(), c2) and
			containsExpr(op.getRightOperand(), c1)
		)
	)
	or
	exists(ConditionalExpr cond |
		(
			containsExpr(cond.getCondition(), c1) and
			(
				containsExpr(cond.getThen(), c2)
				or
				containsExpr(cond.getElse(), c2)
			)
		)
		or
		(
			containsExpr(cond.getCondition(), c2) and
			(
				containsExpr(cond.getThen(), c1)
				or
				containsExpr(cond.getElse(), c1)
			)
		)
		or
		(
			containsExpr(cond.getThen(), c1) and
			containsExpr(cond.getElse(), c2)
		)
		or
		(
			containsExpr(cond.getThen(), c2) and
			containsExpr(cond.getElse(), c1)
		)
	)
}

predicate callHasMultipleTrackedCallsInArguments(Call call) {
	exists(TrackedCall c1, TrackedCall c2, int i, int j |
		c1 != c2 and
		containsExpr(call.getArgument(i), c1) and
		containsExpr(call.getArgument(j), c2) and
		not strictlySequencedOrNotBothEvaluated(c1, c2)
	)
}

predicate binaryOpHasTrackedCallsOnBothSides(UnsequencedBinaryOperation op) {
	exists(TrackedCall c1, TrackedCall c2 |
		containsExpr(op.getLeftOperand(), c1) and
		containsExpr(op.getRightOperand(), c2) and
		not strictlySequencedOrNotBothEvaluated(c1, c2)
	)
}

predicate queryMessage(Expr e, string message) {
	exists(Call call |
		e = call and
		callHasMultipleTrackedCallsInArguments(call) and
		message =
			"This call has at least two tracked calls (Random/RandomRange/guarded) in its argument expressions, and argument evaluation order is undefined."
	)
	or
	exists(UnsequencedBinaryOperation op |
		e = op and
		binaryOpHasTrackedCallsOnBothSides(op) and
		message =
			"This binary operation has tracked calls on both operands, and operand evaluation order is undefined."
	)
}

from Expr e, string message
where
	queryMessage(e, message)
select e, message
