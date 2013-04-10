require_relative 'identity.rb'
require_relative 'expresion.rb'

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
            raise "Internal: eval_const: invalid op? '#{op}'"
    end
end

# Expression * Symbol * Expression * IdentifierList -> nil
# Checks a single expresion to ensure that function and array identifiers
# are properly used.
# Raises an exception on error
def check_op(left, op, right, ident_list)
    case op

    when :call
        ident = ident_list.get(left)
        unless ident != nil and ident.is_a? Function
            raise "Type Mismatch: '#{ident}' is not a function"
        end

    when :array_access
        ident = ident_list.get(left)
        unless ident != nil and ident.is_a? Variable and ident.is_array?
            raise "Type Mismatch: '#{ident}' is not an array"
        end
    end
end

# Expression * IdentifierList -> nil
#
# Params:
#   expression:Expression - expression to be checked
#   ident_list:IdentifierList - list containing all defined vars/funcs
# Result:
#   Exception raised on error

def check_expression(expression, ident_list)
    if expression == nil
        return
    end

    if expression.is_a? Integer
        return
    elsif expression.is_a? Symbol
        unless ident_list.has_sym?(expression)
            raise "Unknown identifier '#{expression}'"
        end
    end

    unless expression.is_a? Array
        raise ArgumentError, 'Expression must be array, integer, symbol'
    end

    left  = expression[0]
    right = expression[2]
    op    = expression[1]

    check_op(left, op, right, ident_list)


    left = check_expression(expression[0], ident_list)
    right = check_expression(expression[2], ident_list)
    return left && right
end

def simplify_expression(expression)
    unless expression.is_a? Array
        return expression
    end

    left = expression[0]
    op   = expression[1]
    right= expression[2]

    if left.is_a?(Integer) and right.is_a?(Integer)
        return evaluate_const(left, op, right)
    end

    unless (op == :array_access) or (op == :call)
        left = simplify_expression(left)
    end
    right = simplify_expression(right)

    return [left, op, right]
end

def process_expression(text, ident_list)
    expression = parse_expression(text, true)
    check_expression(expression, ident_list)
    return simplify_expression(expression)
end 

def process_condition(text, ident_list)
    expression = parse_condition(text)
    check_expression(expression, ident_list)
    return simplify_expression(expression)
end
