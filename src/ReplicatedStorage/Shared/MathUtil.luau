-- ReplicatedStorage/Shared/MathUtil.luau
-- This ModuleScript contains reusable code that server and client scripts can require.

local MathUtil = {}

function MathUtil.add(firstNumber: number, secondNumber: number): number
	return firstNumber + secondNumber
end

return MathUtil
