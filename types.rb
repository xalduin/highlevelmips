class Type
    def castable?(other)
        return false
    end
end

class BasicType < Type
    attr_reader :ident, :size, :total_size

    def initialize(ident, size)
        unless size > 0
            raise ArgumentError, "Size must be > 0"
        end

        @ident = ident.to_sym
        @size = size
        @total_size = size
    end

    def castable?(other)
        return @ident == other.ident
    end

    def to_s
        return "#{ident}"
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

WORD_TYPE = IntegerType.new(:word, 4)
HALF_TYPE = IntegerType.new(:half, 2)
BYTE_TYPE = IntegerType.new(:byte, 1)

class ConstantType < IntegerType 
    def initialize()
        super(:const, 4)
    end

    def castable?(other)
        return super(other)
    end
end

CONST_TYPE = ConstantType.new

class AddressType < Type
    SIZE = 4
    attr_reader :element_type, :size, :total_size

    def initialize(type)
        unless type.is_a? Type
            raise ArgumentError, "type must be of class Type"
        end
        @element_type = type
        @size = SIZE
        @total_size = size
    end

    def castable?(other)
        unless other.is_a? AddressType 
            return false
        end

        return @element_type.castable?(other.element_type)
    end

    def base_type
        type = @element_type

        while type.is_a? AddressType
            type = type.element_type
        end

        return type
    end
end

class ArrayType < AddressType
    attr_reader :num_elements

    def initialize(type, num_elements=nil)
        super(type)
        @num_elements = num_elements 

        if num_elements != nil && num_elements <= 0
            raise ArgumentError, "num_elements must be greater than 0"
        end
    end

    def castable?(other)
        unless other.is_a? ArrayType
            return false
        end

        return @element_type.castable?(other.element_type)
    end

    def total_size
        return @size + @element_type.size * @num_elements
    end

    def to_s
        return "#{@element_type.to_s}[]"
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

def new_default_type_table
    table = TypeTable.new

    table.add(WORD_TYPE)
    table.add(HALF_TYPE)
    table.add(BYTE_TYPE)
    table.add(CONST_TYPE)

    return table
end

# Matches:
# 1. Identifier for basic type
# 2. nil if not an array
# 3. Constant (number) for number of array indices
# 4. Address/reference/etc
TYPE_REGEXP = /^([a-zA-Z]\w*)(\[(\d+)?\])?(&+)?$/

# String * TypeTable -> Type
# Params:
#   str:String      - string to parse for type information
#   table:TypeTable - table containing all defined types
# Result:
#   Type representation of the input string
#
#   Exception is thrown if unable to parse string

def process_typestr(str, table, allow_size=true)
    str = str.strip
    
    match = str.match(TYPE_REGEXP)
    unless match
        raise "Unknown type format: '#{str}'"
    end

    # Extract values from match data
    ident = match[1]
    is_array = match[2] != nil
    array_size = match[3]
    references = match[4]

    # If array size is specified, convert from string -> int
    if array_size != nil 
        unless allow_size
            raise "Not allowed to specify array size in: '#{str}'"
        end

        array_size = Integer(array_size)
    end

    # If references are used, record the number of them
    if references != nil
        raise "Reference type unsupported"
        references = references.size
    end
    
    # Look up basic type
    type = table.get_type(ident)
    if type == nil
        raise "Unrecognized type '#{ident}'"
    end

    # If array is used, encapsulate type within array type
    if is_array
        if array_size != nil
            type = ArrayType.new(type, array_size)
        else
            type = ArrayType.new(type)
        end
    end

    # Wrap type in AddressType for each reference used
    if references != nil
        (1..references).each do
            type = AddressType.new(type)
        end
    end

    return type
end
