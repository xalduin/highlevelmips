require_relative 'statement.rb'
require_relative 'expression.rb'
require_relative 'variable.rb'

FUNC_ARGS_REGEXP = /([a-zA-Z]\w*)\s*:\s*([a-zA-Z]+)/

# String * [] -> true/nil
# Returns true on success, nil on failure

# arg_list must be an empty array
# Stores Variables in the arg_list array

def process_args(args, arg_list)
    if args == nil || args.empty?
        return true
    end

    unless arg_list.empty?
        raise "Internal: Arg list must be empty"
    end

    # Array of matches
    arg_defs = args.scan(FUNC_ARGS_REGEXP)

    arg_defs.each do |arg_match|
        name = arg_match[0]
        type = arg_match[1]

        unless Type.include?(type)
            raise "Invalid argument type '#{type}'"
        end

        var = Variable.new(type, name)
        arg_list<< var
    end

    return true
end

# Process a function call declaration
# Returns nil on failure, true on success
#
# Modifies the global table hash in the following ways:
# [:current_func] is set to the name of the declared function
#
# the local table is initialized as such:
# [:instructions] = 0

def process_func_decl(match, func_list, block)

    if block != nil
        raise "Cannot declare a function within another block"
    end

    name = match[1]
    args = match[2]
    result_type = match[9]

    if func_list.has_ident? name
        raise "Redeclared function: '#{name}'"
    end

    if result_type
        unless Type.include?(result_type)
            raise "Invalid return type '#{result_type}'"
        end
    end

    arg_list = []
    process_args(args, arg_list)

    func = Function.new(name, result_type, arg_list)
    func_list.add(func)

    return func
end

# String * match * {} -> true/nil
# Returns true on success, nil on failure

# Checks to ensure that there is a function to be ended by endfunc
#TODO: Ensure that all loops/if statements have been ended
def process_endfunc(func)
    #raise "Stub method: process_endfunc"
    return true
end

NUM_REGEXP = /^(\d)+$/

def process_return(match, func)
    instruction = ReturnInstruction.new(func)
    func.add_instruction(instruction)

    # Check for no return value
    if match[1] == nil
        if func.return_type != nil
            raise "Expected a value to be given for return statement"
        end
        return true
    end

    # Check to see if the return value is a numerical constant
    value = match[1].strip
    match = value.match(NUM_REGEXP)
    if match
        instruction.value = Integer(match[1])
        return true
    end

    # Check to see if the return value is a variable
    var_list = func.var_list
    match = value.match(VAR_REGEXP)
    if match
        var_ident = match[1]
        var = var_list.get(var_ident)

        if var == nil
            raise "Unknown variable '#{var_ident}'"
        end

        instruction.value = var
        return true
    end

    # Assume that expression parsing is necessary
    result = process_noncondition_expression(value, var_list)
    instruction.value = result
    return true
end

class ReturnInstruction
    attr_accessor :value
    attr_reader :func

    def initialize(func)
        @func  = func
        @value = nil
    end

    def render
        label = "func_#{@func.ident}_done"
        result = []

        if value != nil
            register = RS_RETURN + '0'

            if @value.is_a? Integer
                result<< generate_li(register, @value)
            elsif @value.is_a? Variable
                result<< generate_move(register, @value.register)
            else
                result = generate_expression(register, @value, @func.var_list)
            end
        end

        result<< generate_j(label)
        return result
    end
end
