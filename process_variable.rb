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
#   type_table - TypeTable containing all defined basic types
#
# Return:
#   true on success
#
# Raises an exception on type error or variable re-declaration
def process_var(match, block, type_table)
    ident = match[1]
    type = match[2]

    var_list = block.var_list
    if var_list.has_ident?(ident)
        raise "Redeclared variable '#{ident}'"
    end

    type = process_typestr(type, type_table) 
    if type.is_a?(ArrayType)
        raise "Array declaration not currently supported"
    end

    var = Variable.new(type, ident)
    block.add_variable(var)

    return true
end

# Adds an instruction for setting the value of a variable
# Checks to ensure that the variable was previously defined and that it has
# a proper expression
def process_set(match, function, type_table)
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
    value_expression = process_expression(value, ident_list, type_table)

    var_type = var.type
    if array_index
        var_type = var.type.element_type
    end

    unless value_expression.type.castable?(var_type)
        raise "Cannot convert expression type #{value_expression.type.to_s} " +
            "to variable type #{var_type.to_s}"
    end

    instruction = SetVariableInstruction.new(var, value_expression, function)

    # The variable is being used as an array, add array index to instruction
    if array_index
        index_expression = process_expression(array_index, ident_list,
                                                                    type_table)
        instruction.array_index = index_expression

        unless index_expression.type.castable?(WORD_TYPE)
            raise "Cannot convert array index #{index_expression.type.to_s} " +
                "to word type"
        end
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

        if array_index
            result = []
            value_reg = RS_TEMP + "0"
            index_reg = RS_TEMP + "1"
            index_reg_temp = RS_TEMP + "1"

            result += generate_expression(@value, value_reg, true)
            result += generate_expression(@array_index, index_reg_temp, true)

            size = @var.type.size
            if @var.is_array?
                size = @var.type.element_type.size
            end

            # Multiple index by size of data type
            if size > 1
                result<< generate_mul(index_reg, index_reg_temp, size)
            end

            # Add index offset to array address value
            result<< generate_add(index_reg, index_reg, var_reg)

            # Generate different store directions based on array type
            case @var.type.element_type
                when BYTE_TYPE
                    result<< generate_sb(value_reg, 0, index_reg)
                when HALF_TYPE
                    result<< generate_sh(value_reg, 0, index_reg)
                when WORD_TYPE
                    result<< generate_sw(value_reg, 0, index_reg)
                else
                    raise "Unknown var type '#{@var.type}' for set render"
            end
            return result
        end

        # Non-array value
        # Just store the expression in the variable register
        return generate_expression(@value, var_reg, false)
    end

end
