OP_EQUAL = '=='
OP_NOT_EQUAL = '!='
OP_LESS = '<'
OP_LESS_EQUAL = '<='
OP_GREATER = '>'
OP_GREATER_EQUAL = '>='

OP_ADD = '+'
OP_SUB = '-'
OP_MUL = '*'
OP_DIV = '/'

OP_TABLE = {
    OP_EQUAL          => :equal,
    OP_NOT_EQUAL      => :not_equal,
    OP_LESS           => :less,
    OP_LESS_EQUAL     => :less_equal,
    OP_GREATER        => :greater,
    OP_GREATER_EQUAL  => :greater_equal,
    OP_ADD            => :add,
    OP_SUB            => :sub,
    OP_MUL            => :mul,
    OP_DIV            => :div
}

OP_OPPOSITE_TABLE = {
    :equal            => :not_equal,
    :not_equal        => :equal,
    :less             => :greater_equal,
    :less_equal       => :greater,
    :greater          => :less_equal,
    :greater_equal    => :less
}

OP_COMMUTATIVE_TABLE = {
    :add => true,
    :sub => false,
    :mul => true,
    :div => false
}

# :symbol -> bool
# Returns whether the specified operation is a boolean operation
def is_op_conditional(op)
    case op
    when :equal
        return true

    when :not_equal
        return true

    when :less
        return true

    when :less_equal
        return true

    when :greater
        return true

    when :greater_equal
        return true

    else
        return false
    end
    
    puts "is_op_conditional case error"
    return false
end

# Expression regular expression
# 1. left hand side
# 2. operator
# 3. right hand side
EXP_REGEXP = /((?:[a-zA-Z]\w*)|(?:\d+))\s*(\S{1,2})\s*((?:[a-zA-Z]\w*)|(?:\d+))/

CONST_REGEXP = /^(\d+)$/

# int * symbol * int -> bool/int/nil
# evaulates the expression and returns a calculated value
def evaluate_const(left, op, right)
    left = Integer(left)
    right = Integer(right)
    case op
        when :add
            return left + right
        when :sub
            return left - right
        when :mul
            return left * right
        when :div
            return left / right

        when :equal
            return left == right
        when :not_equal
            return left != right
        when :less
            return left < right
        when :less_equal
            return left <= right
        when :greater
            return left > right
        when :greater_equal
            return left >= right
        else
            puts "Invalid operator? '#{op}'"
            return nil
    end
end

def process_expression_helper(text, local_table)
    text.strip!

    # First check if text is a constant
    match = text.match(CONST_REGEXP)
    if match
        return Integer(match[1])
    end

    match = text.match(EXP_REGEXP)
    unless match
        puts "Invalid expression format"
        return nil
    end

    left = match[1]
    operator = match[2]
    right = match[3]

    unless OP_TABLE.has_key?(operator)
        puts "Unknown operator '#{operator}'"
        return nil
    end
    operator = OP_TABLE[operator]

    left_constant  = left.match(CONST_REGEXP) != nil
    right_constant = right.match(CONST_REGEXP) != nil

    result = {}
    result[:op] = operator

    if left_constant
        result[:left] = [:const, left]
    else
        result[:left] = [:ident, left]
        unless lookup_var(left, local_table)
            puts "Unknown variable '#{left}'"
            return nil
        end
    end

    if right_constant
        result[:right] = [:const, right]
    else
        result[:right] = [:ident, right]
        unless lookup_var(right, local_table)
            puts "Unknown variable '#{right}'"
            return nil
        end
    end

    return result
end

# string -> {:left => [:type, value], :op => :type, :right => [:type, value]}
# or, for a constant expression returns an Integer
# Return nil on failure
#
# :type for the array is either :const or :ident
# :type for the operation is one of the above listed
def process_expression(text, local_table)
    result = process_expression_helper(text, local_table)

    if result == nil
        return nil
    elsif result.is_a? Integer
        return result
    end

    left_constant  = result[:left][0] == :const
    right_constant = result[:right][0] == :const
    operator = result[:op]

    if left_constant and right_constant
        left = result[:left][1]
        right = result[:right][1]

        result = evaluate_const(left, operator, right)

        if result == nil
            puts "Unable to evaluate constant expression"
            return nil
        end

        if result == true
            return 1
        elsif result == false
            return 0
        else
            return result
        end
    end

    return result
end
 
def process_noncondition_expression(text, local_table)
    result = process_expression(text, local_table)

    if result == nil
        return nil
    end

    if result.is_a? Integer
        return result
    end

    if is_op_conditional(result[:op])
        puts "Expected non conditional expression"
        return nil
    end

    return result
end

# string -> {:left => [:type, value], :op => :type, :right => [:type, value]}
# or, for a constant expression
# true/false
# Return nil on failure
#
# :type for the array is either :const or :ident
# :type for the operation is one of the above listed
def process_condition(text, local_table)
    result = process_expression_helper(text, local_table)

    if result == nil
        return nil
    end

    operator = result[:op]

    unless is_op_conditional(operator)
        puts "Given operator isn't conditional '#{operator}'"
        return nil
    end

    left_constant  = result[:left][0] == :const
    right_constant = result[:right][0] == :const

    if left_constant and right_constant
        left = result[:left][1]
        right = result[:right][1]
        result = evaluate_const(left, operator, right)

        if result == nil
            puts "Unable to evaluate constant expression"
            return nil
        end

        if result == true
            return true
        elsif result == false
            return false
        else
            puts "Must use conditional operation?"
            return nil
        end
    end

    return result
end
