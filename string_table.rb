require_relative 'instructions.rb'

class StringTable
    LABEL_PREFIX = "__str"
    attr :string_table, :current_index

    def add(str)
        str = str.to_sym
        unless @string_table.has_key? str
            @string_table[str] = @current_index
            @current_index += 1
        end
    end

    def get_index(str)
        str = str.to_sym
        return @string_table[str]
    end

    def get_label(str)
        str = str.to_sym
        index = @string_table[str]

        if index == nil
            return nil
        end
        return LABEL_PREFIX + index.to_s
    end

    def include?(str)
        return @string_table.has_key?(str.to_sym)
    end

    # [String]
    # Generate .asciiz instructions for all string data
    # And adds corresponding label to them
    def render
        result = []
        @string_table.each_pair do |str, index|
            label = LABEL_PREFIX + index.to_s
            result<< generate_label(label)
            result<< generate_asciiz(str)
        end

        return result
    end

    def initialize
        @string_table = {}
        @current_index = 0
    end
end
