require_relative 'statement.rb'
require_relative 'expression.rb'
require_relative 'variable.rb'
require_relative 'function.rb'
require_relative 'process_variable.rb'

FUNC_CALL_REGEXP = /\w+/

# String * [Variable] * Function -> Array
# Returns an array o
#
# Hash format:
# :type => :const or :var
#
# :value => 
#   if :const, then the constant value
#   if :var, then the variable index
#
# Result is stored in result_list
def process_func_call_args(call_args, func_params, source_func)
    result = []

    if call_args == nil || call_args.empty?
        return result
    end

    index = 0
    local_vars = source_func.var_list
    arg_matches = call_args.scan(FUNC_CALL_REGEXP)

    arg_matches.each do |arg_match|
        arg = arg_match

        # Lookup info on the function parameter's type
        param = func_params[index]
        if param == nil
            raise "Too many arguments supplied to function call"
        end

        match = arg.match(CONST_REGEXP)
        if match
            result<< Integer(arg)

            # Constants are treated as halfs (16-bits)
            # For the purpose of being castable
            unless Type.castable?(:half, param.type)
                raise "Cannont convert constant '#{arg}' to '#{param.type}'"
            end

        else
            var = local_vars.get(arg)
            raise "Unknown variable '#{arg}'" if var == nil

            unless Type.castable?(var.type, param.type)
                raise "Cannot convert '#{arg}:#{var.type}' to #{param.type}"
            end

            result<< var
        end

        index += 1
    end

    if index < func_params.size
        raise "Expected #{func_params.size} arguments, only #{index} supplied"
    end

    return result
end

# MatchData * Function * FunctionList -> true
# True on success, exception thrown on failure
#
# Adds a FunctionCallInstruction to the given function's instruction list
# on success
def process_func_call(match, func, func_list)
    unless func_list.is_a? FunctionList
        raise "Internal: func_list isn't a FunctionList"
    end
    unless func.is_a? Function
        raise "Can only call functions inside other functions"
    end

    expr = process_expression(match[0], func.ident_list)
    unless expr.is_a?(FunctionExpression) or expr.type == nil
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
