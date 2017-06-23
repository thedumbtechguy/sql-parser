module SQLParser
  module Statement
    class Node
      def accept(visitor)
        klass = self.class.ancestors.find do |ancestor|
          visitor.respond_to?("visit_#{demodulize(ancestor.name)}")
        end

        if klass
          visitor.__send__("visit_#{demodulize(klass.name)}", self)
        else
          raise "No visitor for #{self.class.name}"
        end
      end

      def to_sql
        SQLVisitor.new.visit(self)
      end

      private

      def demodulize(str)
        str.split('::')[-1]
      end
    end

    class OrderBy < Node
      attr_reader :sort_specification

      def initialize(sort_specification)
        @sort_specification = Array(sort_specification)
      end
    end

    class Subquery < Node
      attr_reader :query_specification

      def initialize(query_specification)
        @query_specification = query_specification
      end
    end

    class Select < Node
      attr_reader :list, :from_clause, :where_clause, :group_by_clause, :having_clause, :order_by_clause, :limit_clause

      def initialize(list, from_clause = nil, where_clause = nil, group_by_clause = nil,
                     having_clause = nil, order_by_clause = nil, limit_clause = nil)
        @list = list
        @from_clause = from_clause
        @where_clause = where_clause
        @group_by_clause = group_by_clause
        @having_clause = having_clause
        @order_by_clause = order_by_clause
        @limit_clause = limit_clause
      end
    end

    class SelectList < Node
      attr_reader :columns, :distinct

      def initialize(columns, distinct = false)
        @columns = Array(columns)
        @distinct = distinct
      end
    end

    class All < Node; end

    class FromClause < Node
      attr_reader :tables

      def initialize(tables)
        @tables = Array(tables)
      end
    end

    class OrderClause < Node
      attr_reader :columns

      def initialize(columns)
        @columns = Array(columns)
      end
    end

    class LimitClause < Node
      attr_reader :count, :offset

      def initialize(count, offset = nil)
        @count = count
        @offset = offset
      end
    end

    class OrderSpecification < Node
      attr_reader :column

      def initialize(column)
        @column = column
      end
    end

    class Ascending < OrderSpecification; end

    class Descending < OrderSpecification; end

    class HavingClause < Node
      attr_reader :search_condition

      def initialize(search_condition)
        @search_condition = search_condition
      end
    end

    class GroupByClause < Node
      attr_reader :columns

      def initialize(columns)
        @columns = Array(columns)
      end
    end

    class WhereClause < Node
      attr_reader :search_condition

      def initialize(search_condition)
        @search_condition = search_condition
      end
    end

    class On < Node
      attr_reader :search_condition

      def initialize(search_condition)
        @search_condition = search_condition
      end
    end

    class SearchCondition < Node
      attr_reader :left, :right

      def initialize(left, right)
        @left = left
        @right = right
      end
    end

    class Using < Node
      attr_reader :columns

      def initialize(columns)
        @columns = Array(columns)
      end
    end

    class Or < SearchCondition; end

    class And < SearchCondition; end

    class Exists < Node
      attr_reader :table_subquery

      def initialize(table_subquery)
        @table_subquery = table_subquery
      end
    end

    class ComparisonPredicate < Node
      attr_reader :left, :right

      def initialize(left, right)
        @left = left
        @right = right
      end
    end

    class Is < ComparisonPredicate; end

    class Like < ComparisonPredicate; end

    class In < ComparisonPredicate; end

    class InValueList < Node
      attr_reader :values

      def initialize(values)
        @values = values
      end
    end

    class InColumnList < Node
      attr_reader :columns

      def initialize(columns)
        @columns = columns
      end
    end

    class Between < Node
      attr_reader :left, :min, :max

      def initialize(left, min, max)
        @left = left
        @min = min
        @max = max
      end
    end

    class GreaterOrEquals < ComparisonPredicate; end

    class LessOrEquals < ComparisonPredicate; end

    class Greater < ComparisonPredicate; end

    class Less < ComparisonPredicate; end

    class Equals < ComparisonPredicate; end

    class Aggregate < Node
      attr_reader :column

      def initialize(column)
        @column = column
      end
    end

    class Sum < Aggregate; end

    class Minimum < Aggregate; end

    class Maximum < Aggregate; end

    class Average < Aggregate; end

    class Count < Aggregate; end

    class JoinedTable < Node
      attr_reader :left, :right

      def initialize(left, right)
        @left = left
        @right = right
      end
    end

    class CrossJoin < JoinedTable; end

    class QualifiedJoin < JoinedTable
      attr_reader :search_condition

      def initialize(left, right, search_condition)
        super(left, right)
        @search_condition = search_condition
      end
    end

    class InnerJoin < QualifiedJoin; end

    class LeftJoin < QualifiedJoin; end

    class LeftOuterJoin < QualifiedJoin; end

    class RightJoin < QualifiedJoin; end

    class RightOuterJoin < QualifiedJoin; end

    class FullJoin < QualifiedJoin; end

    class FullOuterJoin < QualifiedJoin; end

    class QualifiedColumn < Node
      attr_reader :table, :column

      def initialize(table, column)
        @table = table
        @column = column
      end
    end

    class Identifier < Node
      attr_reader :name

      def initialize(name)
        @name = name
      end
    end

    class Table < Identifier; end

    class Column < Identifier; end

    class As < Node
      attr_reader :value, :column

      def initialize(value, column)
        @value = value
        @column = column
      end
    end

    class Arithmetic < Node
      attr_reader :left, :right

      def initialize(left, right)
        @left = left
        @right = right
      end
    end

    class Multiply < Arithmetic; end

    class Divide < Arithmetic; end

    class Add < Arithmetic; end

    class Subtract < Arithmetic; end

    class Unary < Node
      attr_reader :value

      def initialize(value)
        @value = value
      end
    end

    class Not < Unary; end

    class UnaryPlus < Unary; end

    class UnaryMinus < Unary; end

    class True < Node; end

    class False < Node; end

    class Null < Node; end

    class Literal < Node
      attr_reader :value

      def initialize(value)
        @value = value
      end
    end

    class DateTime < Literal; end

    class Date < Literal; end

    class String < Literal; end

    class ApproximateFloat < Node
      attr_reader :mantissa, :exponent

      def initialize(mantissa, exponent)
        @mantissa = mantissa
        @exponent = exponent
      end
    end

    class Float < Literal; end

    class Integer < Literal; end
  end
end
