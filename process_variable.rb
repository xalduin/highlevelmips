require_relative 'statement.rb'
require_relative 'variable.rb'
require_relative 'process_expression.rb'
require_relative 'render_expression.rb'
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

    var = Variable.new(type, ident, is_array)
    block.add_variable(var)

    return true
end

# Adds an instruction for setting the value of a variable
# Checks to ensure that the variable was previously defined and that it has
# a proper expression
def process_set(match, function)
    name = match[1]
    array_index = match[3]
    value = match[4]

    # Error checking:
    unless function.is_a? Function
        raise "Can only set variables inside functions"
    end

    var_list = function.var_list
    unless var_list.include?(name)
        raise "Undeclared variable '#{name}'"
    end

    var = function.var_list.get(name)
    if array_index != nil and (not var.is_array?)
        raise "Cannot use array index on non-array variable"
    end

    # Parse value and create instruction
    ident_list = function.ident_list
    value_expression = process_expression(value, ident_list)
    instruction = SetVariableInstruction.new(var, value_expression, function)

    # The variable is being used as an array, add array index to instruction
    if array_index
        index_expression = process_expression(array_index, ident_list)
        instruction.array_index = index_expression
    end

    function.add_instruction(instruction)
    return true
end

class SetVariableInstruction
    attr_accessor :var, :array_index, :value, :func

    def initialize(var, value, func, array_index=nil)
        @var = var
        @value = value
        @func = func
        @array_index = array_index
    end

    def render
        var_reg = @var.register
        temp_reg = RS_TEMP + "0"

        result = []
        if array_index
            index_reg = RS_TEMP + "1"

            # Direct address given
            if @array_index.type.to_s.end_with? "_address"
                result += generate_expression(@array_index, index_reg, true)

            # Integer address given, compute address
            else
                result += generate_expression(@array_index, index_reg, false)
                size = Type.size(@var.type)
                if size > 1
                    result<< generate_mul(index_reg, index_reg, size)
                end
                result<< generate_add(index_reg, index_reg, var_reg)
            end

            # Generate different store directions based on array type
            case @var.type
                when :byte
                    result<< generate_sb(temp_reg, 0, index_reg)
                when :half
                    result<< generate_sh(temp_reg, 0, index_reg)
                when :word
                    result<< generate_sw(temp_reg, 0, index_reg)
            end
            return result
        end

        # Non-array values are a cakewalk
        # Just store the expression in the variable register
        return generate_expression(@value, var_reg, false)
    end

end
