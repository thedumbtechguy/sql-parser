module SQLParser
  class Visitor
    def initialize(&block)
      @block = block
    end

    def visit(node)
      @block.call(node)

      node.instance_variables.each do |name|
        value = node.instance_variable_get(name)
        Array(value).each do |item|
          visit(item) if item.is_a?(Statement::Node)
        end
      end
    end
  end
end
