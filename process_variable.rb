require_relative 'statement.rb'
require_relative 'variable.rb'
require_relative 'expression.rb'
require_relative 'function.rb'
require_relative 'instructions.rb'

# MatchData * VariableList -> true/false
# Process a variable declaration line
# Params:
#   match - MatchData for the variable declaration
#   var_list - VariableList to add this variable to
#
# Return:
#   true on success
#
# Raises an exception on type error or variable re-declaration
def process_var(match, block)
    var_list = block.var_list
    ident = match[1]
    type = match[2]
    is_array = (match[3] != nil)

    if var_list.has_ident?(ident)
        raise "Redeclared variable '#{ident}'"
    end

    if is_array
        type = type + "_array"
    end

    var = Variable.new(type, ident)
    block.add_variable(var)

    return true
end

# Adds an instruction for setting the value of a variable
# Checks to ensure that the variable was previously defined and that it has
# a proper expression
def process_set(match, function)
    name = match[1]
    value = match[2]

    unless function.is_a? Function
        raise "Can only set variables inside functions"
    end

    var_list = function.var_list
    unless var_list.include? name
        raise "Undeclared variable '#{name}'"
    end

    var = function.var_list.get(name)

    value = process_noncondition_expression(value, function.var_list)
    raise "Unable to parse expression '#{value}'" if value == nil

    instruction = SetVariableInstruction.new(var, nil, value, function)

    if value.is_a? Integer
        instruction.value_type = :const
    elsif value.is_a? Variable
        instruction.value_type = :var
    else
        instruction.value_type = :expression
    end

    function.add_instruction(instruction)
    return true
end

class SetVariableInstruction
    attr_accessor :var, :value_type, :value, :func

    def initialize(var, value_type, value, func)
        @var = var
        @value_type = value_type
        @value = value
        @func = func
    end

    def render
        var_register = RS_LOCAL + var.num.to_s

        if @value_type == :const
            return [generate_li(var_register, value)]
        elsif @value_type == :var
            return [generate_move(var_register, @value.register)]
        else
            return generate_expression(var_register, @value, func.var_list)
        end
    end

end
