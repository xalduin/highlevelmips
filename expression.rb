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
    :div => false,

    :equal         => true,
    :not_equal     => true,
    :less          => false,
    :less_equal    => false,
    :greater       => false,
    :greater_equal => false
}

OP_CONDITION_LIST = [OP_EQUAL, OP_NOT_EQUAL, OP_LESS, OP_LESS_EQUAL,
    OP_GREATER, OP_GREATER_EQUAL]

class Expression
    attr_accessor :value, :type

    def initialize
        @value = nil
        @type = nil
    end
end

class ConstantExpression < Expression
    def initialize(value)
        unless value.is_a? Integer
            raise ArgumentError, 'value must be an Integer'
        end

        super()
        @value = value
        @type = :const
    end
end

class OperatorExpression < Expression
    attr_accessor :left, :op, :right

    def initialize(left, op, right)
        unless OP_TABLE.has_value? op
            raise ArgumentError, "Unknown operator '#{op}'"
        end

        @left = left
        @op = op
        @right = right
    end
end


class ConditionExpression < OperatorExpression
    def initialize(left, op, right)
        unless OP_CONDITION_LIST.include?(op)
            raise ArgumentError, "Conditional operator expected"
        end
        super(left, op.to_sym, right)
    end
end
class ArithmeticExpression < OperatorExpression
    def initialize(left, op, right)
        if OP_CONDITION_LIST.include?(op)
            raise ArgumentError, "Conditional operator not allowed"
        end
        super(left, op.to_sym, right)
    end
end

class FunctionExpression < Expression
    attr_accessor :args
    def initialize(ident, args)
        super()
        @value = ident.to_sym
        @type = nil
        @args = args
    end
end

class VariableExpression < Expression
    attr_accessor :array_index
    def initialize(ident, array_index)
        super()
        @value = ident.to_sym
        @array_index = nil
    end
end
