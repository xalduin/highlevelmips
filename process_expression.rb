require_relative 'type.rb'
require_relative 'expression.rb'

require_relative 'identifier.rb'
require_relative 'parse_expression.rb'

# int * symbol * int -> bool/int/nil
# evaulates the expression and returns a calculated value
def evaluate_const(left, op, right)
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

# FunctionExpression * IdentifierList -> nil
def check_func_call(expression, ident_list)
    func = expression.value

    param_list = func.arg_list
    if args.size != param_list.size
        raise "Expected #{param_list.size} arguments but found #{args.size}"
    end

    args.each_with_index do |arg, index|
        param = param_list[index]

        arg_type = arg.type
        if arg.type == :const
            arg_type = :half
        end
        unless Type.castable?(arg_type, param.arg_type)
            raise "Arg #'#{index}': #{arg_type} cant convert to '#{param.type}'"
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
        return nil
    end

    case expression

        # Nothing to be done
        when ConstantExpression
            return

        # Ensure that the identifier has been defined as a variable and then
        # Change the expression's value to that variable
        when VariableExpression
            var = ident_list.get(expression.value)

            # Check for variable definition
            unless var != nil or var.is_a? Variable
                raise "Unknown variable '#{expression.value}'"
            end

            if var.is_array? and expression.array_index == nil
                expression.type = (var.type.to_s + "_array").to_sym
            else
                expression.type = var.type
            end
            expression.value = var

        # Check that the identifier has been defined as a function and then
        # Change the expression's value to that function
        # Then check function arguments
        when FunctionExpression
            func = ident_list.get(expression.value)

            # Ensure that the given identifieris a function
            unless func != nil or func.is_a? Function
                raise "Unknown function '#{expression.value}'"
            end

            expression.value = func
    
            # Check each argument (updates their type values)
            expression.args.each do |arg|
                check_expression(arg)
            end

            check_func_call(expression, ident_list)

        # Operators have both a left and right side, so process those first
        #   
        # Then ensure that the type of the right side can be cast to the
        # type of the left side.
        #   
        # Finally, change the type of the current expression to that of the left
        # one
        when OperatorExpression 
            check_expression(left)
            check_expression(right)

            unless Type.castable?(right.type, left.type)
                raise "Cannot cast '#{right.type}' to '#{left.type}'"
            end
            expression.type = left.type

        else
            raise "Unrecognized expression '#{expression}'"
    end
end

# Expresssion -> Expression
# Simplifies any OperatorExpressions when both the left and right sides
# are constants
def simplify_expression(expression)
    unless expression.is_a? OperatorExpression
        return expression
    end

    op    = expression.op
    left  = simplify_expression(expression.left)
    right = simplify_expression(expression.right)

    # If both sides of expression are constants, we can find the result
    if left.is_a? ConstantExpression and right.is_a? ConstantExpression
        return ConstantExpression.new(evaluate_const(left.value,
                                                     op,
                                                     right.value))
    end

    expression.left = left
    expression.right = right
    return expression
end

# String * IdentifierList -> Expression
def process_expression(text, ident_list)
    expression = parse_expression(text, true)
    check_expression(expression, ident_list)
    return simplify_expression(expression)
end 

# String * IdentifierList -> Expression
def process_condition(text, ident_list)
    expression = parse_condition(text)
    check_expression(expression, ident_list)
    return simplify_expression(expression)
end
