require_relative 'types.rb'
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
    args = expression.args

    param_list = func.arg_list
    if args.size != param_list.size
        raise "Expected #{param_list.size} arguments but found #{args.size}"
    end

    args.each_with_index do |arg, index|
        param = param_list[index]

        unless arg.type.castable?(param.type)
            raise "Arg #'#{index}': #{arg.type} cant convert to '#{param.type}'"
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

def check_expression(expression, ident_list, type_table)
    if expression == nil
        return nil
    end

    case expression

        # Nothing to be done
        when ConstantExpression
            expression.type = CONST_TYPE
            return

        # Ensure that the identifier has been defined as a variable and then
        # Change the expression's value to that variable
        when VariableExpression
            var = ident_list.get(expression.value)

            # Check for variable definition
            unless var != nil or var.is_a? Variable
                raise "Unknown variable '#{expression.value}'"
            end

            unless var.is_array? or expression.array_index == nil
                raise "Cannot use array index with non-array variable " +
                    "'#{expression.value}'"
            end

            # Make sure array_index is used with array
            if var.is_array? and expression.array_index == nil
                raise "Must use array index with array"
            end

            expression.value = var
            expression.type = var.type

            # Special handling for arrays
            if var.is_array? and expression.array_index != nil
                check_expression(expression.array_index, ident_list, type_table)
                index_type = expression.array_index.type

                # Non-address array index must be converted to word
                unless index_type.castable?(WORD_TYPE)
                    raise "Array index error: Cannot convert " +
                        "'#{index_type}' to word"
                end

                expression.type = var.type.element_type
            end

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
            expression.type = func.return_type
    
            # Check each argument (updates their type values)
            expression.args.each do |arg|
                check_expression(arg, ident_list, type_table)
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
            left = expression.left
            right = expression.right
            check_expression(left, ident_list, type_table)
            check_expression(right, ident_list, type_table)

            # Much simpler without address things in the way
            unless right.type.castable?(left.type)
                raise "Cannot convert '#{right.type}' to '#{left.type}'"
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
def process_expression(text, ident_list, type_table)
    expression = parse_expression(text, true)
    check_expression(expression, ident_list, type_table)
    return simplify_expression(expression)
end 

# String * IdentifierList -> Expression
def process_condition(text, ident_list, type_table)
    expression = parse_condition(text)
    check_expression(expression, ident_list, type_table)
    return simplify_expression(expression)
end
