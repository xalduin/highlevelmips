require_relative 'types.rb'
require_relative 'Identifier.rb'

class Variable < Identifier
    # Can be used in structs for offsets or for s register number
    attr_accessor :num, :register

    def initialize(type, identifier)
        identifier = identifier.to_sym
        super(identifier, type)

        # Ensure that a valid type is being used
        unless type.is_a? Type
            raise "Invalid type '#{type}'"
        end

        @ident = identifier
        @type  = type

        @num = nil
        @register = nil
    end

    def is_array?
        return @type.is_a? ArrayType
    end
end

class VariableList
    attr_reader :variables

    def initialize()
        @variables = {}
    end

    # Variable -> true/false
    # Adds the variable to this list unless it has previously been added
    #
    # Param:
    #   var - The variable that is to be added to this list
    #
    # Returns:
    #   true  - successfully added the Variable
    #   false - Variable is already in this list
    def add(var)
        unless var.is_a? Variable
            raise "Internal: Argument must be Variable '#{var}'"
        end

        if @variables.has_key? var.ident
            return false
        end

        @variables[var.ident] = var
        return true
    end

    # Symbol -> true/false
    # 
    # Param:
    #   ident - the identifier (name) of the Variable to check for
    #
    # Returns:
    #   true if this list contains the specified identifier, false otherwise
    def include?(ident)
        return @variables.has_key?(ident.to_sym)
    end
    def has_ident?(ident)
        return @variables.has_key?(ident.to_sym)
    end

    def get(ident)
        return @variables[ident.to_sym]
    end

    def length
        return @variables.length
    end
    def size
        return @variables.size
    end
    def each
        @variables.each_value do |value|
            yield value
        end
    end
end
