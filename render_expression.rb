require_relative 'type.rb'
require_relative 'expression.rb'

# VariableExpression * String * Bool -> [String]
def generate_variable_expression(expression, dest, overwrite=false)

    unless expression.is_a? VariableExpression
        raise ArgumentError, "Expression must be a VariableExpression"
    end

    var = expression.value
    var_reg = var.register

    # No array index = move instruction
    if expression.array_index == nil
        unless overwrite
            return [generate_move(dest, reg)]
        else
            # Overwritting allowed, no move instruction necessary
            dest.replace(reg)
            return []
        end
    end

    addr_reg = RS_TEMP + "0"
    is_address = expression.array_index.type.to_s.ends_with?("_address")
    result = generate_expression(expression.array_index, temp_reg, true)

    # Convert integer offset into address
    unless is_address
        # It's okay to re-use t0
        temp_reg = RS_TEMP + "0"
        size = Type.size(var.type)

        result<< generate_mul(temp_reg, addr_reg, size)
        result<< generate_add(temp_reg, var_reg, temp_reg)
        addr_reg = temp_reg
    end

    # Generate load instruction depending on type of data
    case var.type
        when :byte
            result<< generate_lb(dest, 0, addr_reg)
        when :half
            result<< generate_lh(dest, 0, addr_reg)
        when :word
            result<< generate_lw(dest, 0, addr_reg)
    end
    return result
end

def generate_operator_expression(expression, dest, overwrite=false)
    left_reg  = RS_TEMP + "0"
    right_reg = RS_TEMP + "1"
    result = []

    left = expression.left
    right = expression.right

    left_const  = left.type == :const
    right_const = right.type == :const
    op = expression.op

    # left or right, but not both are constant
    if left_const
        right_const = true
        if OP_COMMUTATIVE_TABLE[op] == true
            expression.left = right
            expression.right = left

        # Subtraction can be implemented as negative addition
        elsif op == :sub
            left.value = -left.value
            expression.op = :add
            expression.left = right
            expression.right = left
        else
            left_const = false
            right_const = false
            result += generate_expression(left, left_reg, true)
        end
    elsif (not right_const)
        result += generate_expression(right, right_reg, true)
    end

    if overwrite
        dest.replace left_reg
    end

    case expression.op
        when :add
            if right_const
                result<< generate_addi(dest, left_reg, expression.right.value)
            else
                result<< generate_add(dest, left_reg, right_reg)
            end
        when :sub
            if right_const
                result<< generate_addi(dest, left_reg, -expression.right.value)
            else
                result<< generate_sub(dest, left_reg, right_reg)
            end
        when :mul
            if right_const
                result<< generate_mul(dest, left_reg, expression.right.value)
            else
                result<< generate_mul(dest, left_reg, right_reg)
            end
        when :div
            if right_const
                result<< generate_div(dest, left_reg, expression.right.value)
            else
                result<< generate_div(dest, left_reg, right_reg)
            end
    end

    return result
end  

def generate_expression(expression, dest, overwrite=false)
    case expression
        when ConstantExpression
            value = expression.value

            if value == true
                return [generate_li(dest, 1)]
            elsif value == false
                return [generate_li(dest, 0)]
            end

            return [generate_li(dest, value)]

        when VariableExpression
            return generate_variable(expression, dest, overwrite)

        when OperatorExpression
            return generate_operator_expression(expression, dest, overwrite)
    end
end

def generate_condition(expression, dest_label)
    unless expression.is_a? ConditionExpression
        raise ArgumentError, "Expression must be a ConditionExpression"
    end

    left_reg = RS_TEMP + "0"
    right_reg = RS_TEMP + "1"
    op = expression.op

    result = []
    result += generate_expression(expression.left, left_reg, true)
    result += generate_expression(expression.right, right_reg, true)

    temp_reg = RS_TEMP + "2"
    if op == :less or op == :greater_equal
        result<< generate_slt(temp_reg, left_reg, right_reg)

    elsif op == :less_equal or op == :greater
        result<< generate_sub(temp_reg, left_reg, right_reg)
    end

    case op
        when :equal
            result<< generate_beq(left_reg, right_reg, dest_label)
        when :not_equal
            result<< generate_bne(left_reg, right_reg, dest_label)
        when :less
            result<< generate_bne(temp_reg, R_ZERO, dest_label)
        when :greater_equal
            result<< generate_beq(temp_reg, R_ZERO, dest_label)
        when :less_equal
            result<< generate_blez(temp_reg, dest_label)
        when :greater
            result<< generate_bgtz(temp_reg, dest_label)
        else
            raise "Unknown operator '#{op}'"
    end

    return result
end

def generate_condition_negate(expression, dest_label)
    left = expression.left
    right = expression.right
    op = expression.op

    op = OP_OPPOSITE_TABLE[op]
    expression = ConditionExpression.new(right, op, left)

    return generate_condition(expression, dest_label)
end
