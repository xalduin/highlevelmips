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

            unless var.is_array? or expression.array_index == nil
                raise "Cannot use array index with non-array variable " +
                    "'#{expression.value}'"
            end

            # Special handling for arrays
            if var.is_array? and expression.array_index != nil
                check_expression(expression.array_index)
                index_type = expression.array_index.type.to_s

                # Using a pointer instead of integer for array index
                if index_type.ends_with?("_address")
                    index_type.strip!("_address")

                    # When using a memory address var, types must match
                    unless index_type.castable?(var.type)
                        raise "Address type must match variable type:" +
                            "address:'#{index_type}' var:'#{var.type}'"
                    end
                else
                    # Non-address array index must be converted to word
                    unless Type.castable?(index_type, :word)
                        raise "Array index error: Cannot convert " +
                            "'#{index_type}' to word"
                    end
                end

                expression.type = var.type

            # Array variable used without index = pointer mode
            else var.is_array? and expression.array_index == nil
                expression.type = (var.type.to_s + "_address").to_sym
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
            expression.type = func.return_type
    
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

            # Special case for addresses
            op = expression.op
            if left.type.to_s.ends_with?("_address")

                # Cannot use multiplication or division with addresses on
                # either side
                if op == :mul or op == :div
                    raise "Cannot use * or / with address values"
                end

                # If a conditional operator is used, both sides must be
                # addresses
                if OP_CONDITION_LIST.include? op
                    unless right.type.to_s.ends_with("_address")
                        raise "Must use conditional operator with 2 addresses"
                    end
                    expression.type = :byte
                    return
                end

                unless Type.castable?(right.type, :word)
                    raise "Can only add/subtract integer values from addresses"
                end

                expression.type = left.type
                return
            end

            # Much simpler without address things in the way
            unless Type.castable?(right.type, left.type) ||
                   Type.castable?(left.type, right.type)
                raise "Cannot convert between '#{right.type}' + '#{left.type}'"
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
