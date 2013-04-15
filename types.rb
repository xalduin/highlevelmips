class Type
    def castable?(other)
        return false
    end
end

class BasicType < Type
    attr_reader :ident, :size

    def initialize(ident, size)
        unless size > 0
            raise ArgumentError, "Size must be > 0"
        end

        @ident = ident.to_sym
        @size = size
    end

    def castable?(other)
        return @ident == other.ident
    end
end

class IntegerType < BasicType
    def initialize(ident, size)
        super(ident, size)
    end

    def castable?(other)
        return other.is_a? IntegerType
    end
end

class AddressType < Type
    attr_reader :element_type

    def initialize(type)
        unless type.is_a? Type
            raise ArgumentError, "type must be of class Type"
        end
        @element_type = type
    end

    def castable?(other)
        unless other.is_a? AddressType 
            return false
        end

        return @element_type.castable?(other.element_type)
    end
end

class ArrayType < AddressType
    def initialize(type)
        super(type)
    end

    def castable?(other)
        unless other.is_a? ArrayType
            return false
        end

        return @element_type.castable?(other.element_type)
    end
end

class TypeTable
    attr :type_hash

    def initialize
        @type_hash = {}
    end

    def add(type)
        unless type.is_a? Type
            raise ArgumentError, "type must be of class Type"
        end

        @type_hash[type.ident] = type
    end

    def include?(type)
        return @type_hash.has_key? type.ident
    end

    def get_type(ident)
        return @type_hash[ident.to_sym]
    end
end

def create_type_table
    integer_types = {
        :word => 4,
        :half => 2,
        :byte => 1
    }

    table = TypeTable.new

    integer_types.each do |type, size|
        table.add(IntegerType.new(type, size))
    end

    return table
end
