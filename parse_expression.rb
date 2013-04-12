require_relative 'expression.rb'

CONDITION_OPS = ['==', '!=', '<', '<=', '>', '>=']
EXPRESSION_OPS = ['+', '-']
TERM_OPS = ['*', '/']

# String -> ConditionExpression
#
# Param:
#   text:String - input text, will be modified
#
# Result:
#   [left, :op, right]
#   left, right:Expression - values of the left and right sides of condition
#   op:Symbol - the conditional operation being performed

def parse_condition(text)
    left = parse_expression(text)

    text.lstrip!
    op = text[0..1]
    unless CONDITION_OPS.include? op
        op = text[0]
        unless OP_CONDITION_LIST.include? op
            raise "Unknown conditional operator '#{op}'"
        else
            text.slice!(0)
        end
    else
        text.slice!(0..1)
    end

    op = OP_TABLE[op]
    right = parse_expression(text)

    return ConditionExpression.new(left, op, right)
end


# String -> Expression
# Directly modifies input string by deleting characters
#
# Param:
#   text:String - input text, will be modified (deleted)
#
# Result:
#   value:Factor look a
# expresssion = term [{+, -} term]*
def parse_expression(text, consume_all=false)
    result = parse_term(text)

    text.strip!
    if text == nil
        raise "Expected expression but found empty string"
    end

    if text.empty?
        return result
    end

    # Reached the end of known parsing, return
    op = text[0]
    unless EXPRESSION_OPS.include?(op)
        if consume_all
            raise "Unrecognized char '#{op}' in expression"
        end

        return result
    end
    text.slice!(0)

    op = OP_TABLE[op]
    right = parse_expression(text, false)

    return ArithmeticExpression.new(result, op, right)
end

# String -> Expression
def parse_term(text)
    result = parse_factor(text)

    text.lstrip!
    if text.empty?
        return result
    end

    # If it's not a term operator (* or /), then we're done here
    op = text[0]
    unless TERM_OPS.include?(op)
        return result
    end
    text.slice!(0)

    op = OP_TABLE[op]
    right = parse_term(text)

    return ArithmeticExpression.new(result, op, right)
end

# Numbers, includes hex, binary, octal
# 0xabcdef for hex
# 0b10 for binary
# 01234567 for octal
# 124567890 for decimal
NUM_REGEXP = /^
    (
        (?:\-?0[xX][a-fA-F\d]+)
        |
        (?:\-?0[bB][01]+)
        |
        (?:\-?0[0-7]+)
        |
        (?:\-?\d+)
    )/x

CHAR_REGEXP = /^'.'/
STRING_REGEXP = /^"((?:.*(?:\\")*)*?)"/

IDENT_REGEXP = /^([a-zA-Z]\w*)/

#array
ARRAY_REGEXP = /^\[ \s* (.+) \s* \]/x

FUNC_REGEXP = /^\( \s* (.*) \s* \)/x

# Factors are:
#   numbers
#   identifiers (just an identifier = variable)
#   an expression inside parenthesis

# String -> Expression
def parse_factor(text)
    text.lstrip!

    char = text[0]

    if char == nil
        raise "Expected non-empty string for factor"
    end

    if char == '('
        text.slice!(0)
        result = parse_expression(text)
        char = text.slice!(0)

        unless char == ')'
            raise "Expected ')' but read '#{char}'"
        end

        return result

    elsif char == "'"
        char = text.slice!(0..2)

        if char[2] != "'"
            raise "Expected char expression but found no closing single quote"
        end

        val = char[1].ord
        return ConstantExpression.new(val)

    elsif char.match(IDENT_REGEXP)
        ident = text.slice!(IDENT_REGEXP)

        text.lstrip!
        match = text.slice!(ARRAY_REGEXP)
        unless match == nil or match.empty?
            # The array index is $1
            return VariableExpression.new(ident, parse_expression($1))
        end

        text.lstrip!
        match = text.slice!(FUNC_REGEXP)
        unless match == nil or match.empty?
            func = FunctionExpression.new(ident, [])
            args = $1

            if args == nil or args.empty?
                return func
            end

            expression = parse_expression(args)
            func.args<< expression

            # Check for additional arguments, comma separated
            char = args[0]
            while char == ','
                args.slice!(0)
                expression = parse_expression(args)

                func.args<< expression
                char = args[0]
            end

            if args != nil and (not args.empty?)
                raise "Failed to parse function arguments"
            end

            return func
        end

        return VariableExpression.new(ident, nil)
    else
        match = text.slice!(NUM_REGEXP)
        if match == nil or match.empty?
            puts "Text: '#{text}', match = '#{match}'"
            raise "Unrecognized factor in expression"
        end
        num = Integer(match)
        return ConstantExpression.new(num)
    end
end
