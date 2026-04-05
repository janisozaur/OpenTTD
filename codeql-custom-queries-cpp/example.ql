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

predicate containsTrackedCall(Expr expr) {
	exists(TrackedCall call |
		containsExpr(expr, call)
	)
}

predicate callHasMultipleTrackedCallsInArguments(Call call) {
	exists(TrackedCall c1, TrackedCall c2, int i, int j |
		c1 != c2 and
		containsExpr(call.getArgument(i), c1) and
		containsExpr(call.getArgument(j), c2)
	)
}

predicate binaryOpHasTrackedCallsOnBothSides(UnsequencedBinaryOperation op) {
	containsTrackedCall(op.getLeftOperand()) and
	containsTrackedCall(op.getRightOperand())
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
