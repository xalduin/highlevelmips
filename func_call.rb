require_relative 'expression.rb'
require_relative 'process_expression.rb'
require_relative 'function.rb'

# MatchData * Function * FunctionList -> true
# True on success, exception thrown on failure
#
# Adds a FunctionCallInstruction to the given function's instruction list
# on success
def process_func_call(match, func, func_list, type_table)
    unless func_list.is_a? FunctionList
        raise "Internal: func_list isn't a FunctionList"
    end
    unless func.is_a? Function
        raise "Can only call functions inside other functions"
    end

    expr = process_expression(match[0], func.ident_list, type_table)
    unless expr.is_a?(FunctionExpression)
        raise "Invalid function call expression?"
    end

    instruction = FunctionCallInstruction.new(func, expr)
    func.add_instruction(instruction)

    return true
end

class FunctionCallInstruction
    attr :func, :expr

    # Params:
    #   func: Function - the function callee
    #   func_target: Function - the function called
    #   args: [Variable | Integer] - in-order list of function arguments
    def initialize(func, expr)
        @func = func
        @expr = expr
    end

    def render
        return generate_function_expression(@expr, @func.ident, false)
    end
end
