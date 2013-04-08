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

    var_name = match[1]
    func_name = match[2]
    call_args = match[3]

    func_target = func_list.get_ident(func_name)

    if func_target == nil
        raise "Trying to call undeclared function '#{func_name}'"
    end

    arg_list = process_func_call_args(call_args, func_target.arg_list, func)
    instruction = FunctionCallInstruction.new(func, func_target, arg_list)
    func.add_instruction(instruction)

    # Check if it's requested to save return value
    if var_name != nil

        # Check to make sure that the variable is defined
        var = func.var_list.get(var_name)
        if var == nil 
            raise "Unknown variable '#{var_name}'"
        end

        return_type = func_target.return_type
        # Type check return type with variable type
        unless Type.castable?(return_type, var.type)
            raise "Cannot cast return type #{return_type} to #{var.type}"
        end

        instruction.var_result = var
    end

    return true
end

class FunctionCallInstruction
    attr :func, :func_target, :args
    attr_writer :var_result

    # Params:
    #   func: Function - the function callee
    #   func_target: Function - the function called
    #   args: [Variable | Integer] - in-order list of function arguments
    def initialize(func, func_target, args)
        @func = func
        @func_target = func_target
        @args = args
        @var_result = nil
    end

    def render
        result = []
        index = 0
        @args.each do |var|
            arg_register = RS_ARG + index.to_s

            # Constants loaded into arg register through load immediate
            if var.is_a? Integer
                result<< generate_li(arg_register, var)

            # Local variables are in registers, move instruction used
            else
                var_register = RS_LOCAL + var.num.to_s
                result<< generate_move(arg_register, var_register)
            end
            index += 1
        end

        label = "func_#{func_target.ident}"
        result<< generate_jal(label)

        if @var_result != nil
            result<< generate_move(@var_result.register, RS_RETURN + "0")
        end

        return result
    end
end
