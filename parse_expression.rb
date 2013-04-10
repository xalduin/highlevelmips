require_relative 'expression.rb'

CONDITION_OPS = ['==', '!=', '<', '<=', '>', '>=']
EXPRESSION_OPS = ['+', '-']
TERM_OPS = ['*', '/']

# String -> [left, :op, right]
#
# Param:
#   text:String - input text, will be modified
#
# Result:
#   [left, :op, right]
#   left, right:Expression - values of the left and right sides of condition
#   op:Symbol - the conditional operation being performed

def parse_condition(text)
    result = []

    result<< parse_expression(text)

    text.lstrip!
    op = text[0..1]
    unless CONDITION_OPS.include? op
        raise "Unknown conditional operator '#{op}'"
    end
    text.slice!(0..1)
    result<< OP_TABLE[op]

    result<< parse_expression(text)

    return result
end


# String -> [left, :op, right] or value
# Directly modifies input string by deleting characters
#
# Param:
#   text:String - input text, will be modified (deleted)
#
# Result:
#   value:Factor look a
# expresssion = term [{+, -} term]*
def parse_expression(text, consume_all=false)
    result = []

    result<< parse_term(text)

    text.strip!
    if text == nil
        raise "Expected expression but found empty string"
    end

    until text == nil or text.empty?
        op = text[0]

        # Reached the end of known parsing, return
        unless EXPRESSION_OPS.include?(op)
            if consume_all
                raise "Unrecognized char '#{op}' in expression"
            end

            if result.size == 1
                return result[0]
            end
            return result
        end

        text.slice!(0)
        result<< OP_TABLE[op]
        result<< parse_expression(text, false)
        text.strip!
    end

    if result.empty?
        raise "Failed to parse expression"
    elsif result.size == 1
        return result[0]
    end

    return result
end

def parse_term(text)
    result = []

    result<< parse_factor(text)

    text.lstrip!
    until text.empty?
        op = text[0]

        # If it's not a term operator (* or /), then we're done here
        unless TERM_OPS.include?(op)
            if result.size == 1
                return result[0]
            end
            return result
        end
        text.slice!(0)

        result<< OP_TABLE[op]
        result<< parse_term(text)
        text.lstrip!
    end

    if result.size == 1
        return result[0]
    end
    return result
end

# Numbers, includes hex, binary, octal
# 0xabcdef for hex
# 0b10 for binary
# 01234567 for octal
# 124567890 for decimal
NUM_REGEXP = /^
    (
        (:?\-?0[xX][a-fA-F\d]+)
        |
        (:?\-?0[bB][01]+)
        |
        (:?\-?0[0-7]+)
        |
        (:?\-?\d+)
    )/x
IDENT_REGEXP = /^([a-zA-Z]\w*)/

#array
ARRAY_REGEXP = /^\[ \s* (.+) \s* \]/x

FUNC_REGEXP = /^\( \s* (.*) \s* \)/x

# Factors are:
#   numbers
#   identifiers (just an identifier = variable)
#   an expression inside parenthesis
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

    elsif char.match(IDENT_REGEXP)
        ident = text.slice!(IDENT_REGEXP)

        text.lstrip!
        match = text.slice!(ARRAY_REGEXP)
        unless match == nil or match.empty?
            # The array index is $1
            return [ident.to_sym, :array_access, parse_expression($1)]
        end

        text.lstrip!
        match = text.slice!(FUNC_REGEXP)
        unless match == nil or match.empty?
            args = $1
            func = [ident.to_sym, :call]

            if args == nil or args.empty?
                return func
            end

            expression = parse_expression(args)
            func<< expression
            char = args[0]
            while char == ','
                args.slice!(0)
                expression = parse_expression(args)
                func<< expression
                char = args[0]
            end

            if args != nil and (not args.empty?)
                raise "Failed to parse function arguments"
            end

            return func
        end

        return ident.to_sym
    else
        match = text.slice!(NUM_REGEXP)
        if match == nil or match.empty?
            puts "Text: '#{text}', match = '#{match}'"
            raise "Unrecognized factor in expression"
        end
        num = Integer(match)
        return num
    end
end
