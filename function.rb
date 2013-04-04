require_relative 'type.rb'
require_relative 'variable.rb'

class Function
    attr_reader :ident, :return_type, :arg_list, :var_list

    def initialize(ident, type, arg_list)
        # Type checking
        unless arg_list.is_a? Array
            raise "arg_list must be an Array"
        end

        type = type.to_sym
        unless Type.include? type
            raise "Unknown type '#{type}'"
        end

        @ident = ident.to_sym
        @return_type = type
        @arg_list = arg_list
        @var_list = VariableList.new()

        arg_list.each do |var|
            @var_list.add(var)
        end
    end
end
