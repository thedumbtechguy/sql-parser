require 'sql-parser/visitor'

module SQLParser
  module Statement
    class Node
      def visit(&block)
        Visitor.new(&block).visit(self)
      end

      def map(&block)
        yield(self) || self
      end
    end

    class Subquery < Node
      attr_reader :query_specification

      def initialize(query_specification)
        @query_specification = query_specification
      end

      def map(&block)
        yield(self) || self.class.new(query_specification.map(&block))
      end

      def to_sql
        "(#{query_specification.to_sql})"
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

      def map(&block)
        yield(self) || self.class.new(*parts.map { |child| child.map(&block) if child })
      end

      def to_sql
        "SELECT #{parts.compact.map { |node| node.to_sql }.join(' ')}"
      end

      private

      def parts
        [
          list,
          from_clause,
          where_clause,
          group_by_clause,
          having_clause,
          order_by_clause,
          limit_clause
        ]
      end
    end

    class SelectList < Node
      attr_reader :columns

      def initialize(columns)
        @columns = Array(columns)
      end

      def map(&block)
        yield(self) || self.class.new(columns.map { |col| col.map(&block) })
      end

      def to_sql
        columns.map { |node| node.to_sql }.join(', ')
      end
    end

    class Distinct < Node
      attr_reader :list

      def initialize(list)
        @list = list
      end

      def map(&block)
        yield(self) || self.class.new(list.map(&block))
      end

      def to_sql
        "DISTINCT #{list.to_sql}"
      end
    end

    class All < Node
      def to_sql
        '*'
      end
    end

    class FromClause < Node
      attr_reader :tables

      def initialize(tables)
        @tables = Array(tables)
      end

      def map(&block)
        yield(self) || self.class.new(tables.map { |table| table.map(&block) })
      end

      def to_sql
        "FROM #{tables.map { |node| node.to_sql }.join(', ')}"
      end
    end

    class OrderClause < Node
      attr_reader :columns

      def initialize(columns)
        @columns = Array(columns)
      end

      def map(&block)
        yield(self) || self.class.new(columns.map { |col| col.map(&block) })
      end

      def to_sql
        "ORDER BY #{columns.map { |node| node.to_sql }.join(', ')}"
      end
    end

    class LimitClause < Node
      attr_reader :count, :offset

      def initialize(count, offset = nil)
        @count = count
        @offset = offset
      end

      def to_sql
        if offset
          "LIMIT #{count} OFFSET #{offset}"
        else
          "LIMIT #{count}"
        end
      end
    end

    class OrderSpecification < Node
      attr_reader :column

      def initialize(column)
        @column = column
      end

      def map(&block)
        yield(self) || self.class.new(column.map(&block))
      end
    end

    class Ascending < OrderSpecification
      def to_sql
        "#{column.to_sql} ASC"
      end
    end

    class Descending < OrderSpecification
      def to_sql
        "#{column.to_sql} DESC"
      end
    end

    class HavingClause < Node
      attr_reader :search_condition

      def initialize(search_condition)
        @search_condition = search_condition
      end

      def map(&block)
        yield(self) || self.class.new(search_condition.map(&block))
      end

      def to_sql
        "HAVING #{search_condition.to_sql}"
      end
    end

    class GroupByClause < Node
      attr_reader :columns

      def initialize(columns)
        @columns = Array(columns)
      end

      def map(&block)
        yield(self) || self.class.new(columns.map { |col| col.map(&block) })
      end

      def to_sql
        "GROUP BY #{columns.map { |node| node.to_sql }.join(', ')}"
      end
    end

    class WhereClause < Node
      attr_reader :search_condition

      def initialize(search_condition)
        @search_condition = search_condition
      end

      def map(&block)
        yield(self) || self.class.new(search_condition.map(&block))
      end

      def to_sql
        "WHERE #{search_condition.to_sql}"
      end
    end

    class On < Node
      attr_reader :search_condition

      def initialize(search_condition)
        @search_condition = search_condition
      end

      def map(&block)
        yield(self) || self.class.new(search_condition.map(&block))
      end

      def to_sql
        "ON #{search_condition.to_sql}"
      end
    end

    class SearchCondition < Node
      attr_reader :left, :right

      def initialize(left, right)
        @left = left
        @right = right
      end

      def map(&block)
        yield(self) || self.class.new(left.map(&block), right.map(&block))
      end
    end

    class Using < Node
      attr_reader :columns

      def initialize(columns)
        @columns = Array(columns)
      end

      def map(&block)
        yield(self) || self.class.new(columns.map { |col| col.map(&block) })
      end

      def to_sql
        "USING (#{columns.map { |node| node.to_sql }.join(', ')})"
      end
    end

    class Or < SearchCondition
      def to_sql
        "(#{left.to_sql} OR #{right.to_sql})"
      end
    end

    class And < SearchCondition
      def to_sql
        "(#{left.to_sql} AND #{right.to_sql})"
      end
    end

    class Exists < Node
      attr_reader :table_subquery

      def initialize(table_subquery)
        @table_subquery = table_subquery
      end

      def map(&block)
        yield(self) || self.class.new(table_subquery.map(&block))
      end

      def to_sql
        "EXISTS #{table_subquery.to_sql}"
      end
    end

    class ComparisonPredicate < Node
      attr_reader :left, :right

      def initialize(left, right)
        @left = left
        @right = right
      end

      def map(&block)
        yield(self) || self.class.new(left.map(&block), right.map(&block))
      end

      def to_sql
        "#{left.to_sql} #{operator} #{right.to_sql}"
      end
    end

    class Is < ComparisonPredicate
      def operator
        'IS'
      end
    end

    class IsNot < ComparisonPredicate
      def operator
        'IS NOT'
      end
    end

    class Like < ComparisonPredicate
      def operator
        'LIKE'
      end
    end

    class NotLike < ComparisonPredicate
      def operator
        'NOT LIKE'
      end
    end

    class In < ComparisonPredicate
      def operator
        'IN'
      end
    end

    class NotIn < ComparisonPredicate
      def operator
        'NOT IN'
      end
    end

    class InValueList < Node
      attr_reader :values

      def initialize(values)
        @values = Array(values)
      end

      def map(&block)
        yield(self) || self.class.new(values.map { |value| value.map(&block) })
      end

      def to_sql
        "(#{values.map { |node| node.to_sql }.join(', ')})"
      end
    end

    class Between < Node
      attr_reader :left, :min, :max

      def initialize(left, min, max)
        @left = left
        @min = min
        @max = max
      end

      def map(&block)
        yield(self) || self.class.new(
          left.map(&block),
          min.map(&block),
          max.map(&block)
        )
      end

      def to_sql
        "#{left.to_sql} BETWEEN #{min.to_sql} AND #{max.to_sql}"
      end
    end

    class NotBetween < Node
      attr_reader :left, :min, :max

      def initialize(left, min, max)
        @left = left
        @min = min
        @max = max
      end

      def map(&block)
        yield(self) || self.class.new(
          left.map(&block),
          min.map(&block),
          max.map(&block)
        )
      end

      def to_sql
        "#{left.to_sql} NOT BETWEEN #{min.to_sql} AND #{max.to_sql}"
      end
    end

    class GreaterOrEquals < ComparisonPredicate
      def operator
        '>='
      end
    end

    class LessOrEquals < ComparisonPredicate
      def operator
        '<='
      end
    end

    class Greater < ComparisonPredicate
      def operator
        '>'
      end
    end

    class Less < ComparisonPredicate
      def operator
        '<'
      end
    end

    class Equals < ComparisonPredicate
      def operator
        '='
      end
    end

    class NotEquals < ComparisonPredicate
      def operator
        '<>'
      end
    end

    class Function < Node
      attr_reader :name, :arguments

      def initialize(name, arguments = nil)
        @name = name
        @arguments = Array(arguments)
      end

      def map(&block)
        yield(self) || self.class.new(name, arguments.map { |arg| arg.map(&block) })
      end

      def to_sql
        "#{name}(#{arguments.map { |node| node.to_sql }.join(', ')})"
      end
    end

    class JoinedTable < Node
      attr_reader :left, :right

      def initialize(left, right)
        @left = left
        @right = right
      end

      def map(&block)
        yield(self) || self.class.new(left.map(&block), right.map(&block))
      end
    end

    class CrossJoin < JoinedTable
      def to_sql
        "#{left.to_sql} CROSS JOIN #{right.to_sql}"
      end
    end

    class QualifiedJoin < JoinedTable
      attr_reader :search_condition

      def initialize(left, right, search_condition)
        super(left, right)
        @search_condition = search_condition
      end

      def map(&block)
        yield(self) || self.class.new(
          left.map(&block),
          right.map(&block),
          search_condition.map(&block)
        )
      end

      def to_sql
        "#{left.to_sql} #{join_type} JOIN #{right.to_sql} #{search_condition.to_sql}"
      end
    end

    class InnerJoin < QualifiedJoin
      def join_type
        'INNER'
      end
    end

    class LeftJoin < QualifiedJoin
      def join_type
        'LEFT'
      end
    end

    class LeftOuterJoin < QualifiedJoin
      def join_type
        'LEFT OUTER'
      end
    end

    class RightJoin < QualifiedJoin
      def join_type
        'RIGHT'
      end
    end

    class RightOuterJoin < QualifiedJoin
      def join_type
        'RIGHT OUTER'
      end
    end

    class FullJoin < QualifiedJoin
      def join_type
        'FULL'
      end
    end

    class FullOuterJoin < QualifiedJoin
      def join_type
        'FULL OUTER'
      end
    end

    class QualifiedColumn < Node
      attr_reader :table, :column

      def initialize(table, column)
        @table = table
        @column = column
      end

      def map(&block)
        yield(self) || self.class.new(table.map(&block), column.map(&block))
      end

      def to_sql
        "#{table.to_sql}.#{column.to_sql}"
      end
    end

    class Identifier < Node
      attr_reader :name

      def initialize(name)
        @name = name
      end

      def to_sql
        "`#{name}`"
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

      def map(&block)
        yield(self) || self.class.new(value.map(&block), column.map(&block))
      end

      def to_sql
        "#{value.to_sql} AS #{column.to_sql}"
      end
    end

    class Arithmetic < Node
      attr_reader :left, :right

      def initialize(left, right)
        @left = left
        @right = right
      end

      def map(&block)
        yield(self) || self.class.new(left.map(&block), right.map(&block))
      end

      def to_sql
        "(#{left.to_sql} #{operator} #{right.to_sql})"
      end
    end

    class Multiply < Arithmetic
      def operator
        '*'
      end
    end

    class Divide < Arithmetic
      def operator
        '/'
      end
    end

    class Add < Arithmetic
      def operator
        '+'
      end
    end

    class Subtract < Arithmetic
      def operator
        '-'
      end
    end

    class Unary < Node
      attr_reader :value

      def initialize(value)
        @value = value
      end

      def map(&block)
        yield(self) || self.class.new(value.map(&block))
      end
    end

    class Not < Unary
      def to_sql
        "NOT #{value.to_sql}"
      end
    end

    class UnaryPlus < Unary
      def to_sql
        "+#{value.to_sql}"
      end
    end

    class UnaryMinus < Unary
      def to_sql
        "-#{value.to_sql}"
      end
    end

    class True < Node
      def to_sql
        'TRUE'
      end
    end

    class False < Node
      def to_sql
        'FALSE'
      end
    end

    class Null < Node
      def to_sql
        'NULL'
      end
    end

    class Literal < Node
      attr_reader :value

      def initialize(value)
        @value = value
      end

      def to_sql
        value.to_s
      end

      protected

      def escape(str)
        str.gsub(/'/, "''")
      end
    end

    class DateTime < Literal
      def to_sql
        "'%s'" % escape(value.strftime('%Y-%m-%d %H:%M:%S'))
      end
    end

    class Date < Literal
      def to_sql
        "DATE '%s'" % escape(value.strftime('%Y-%m-%d'))
      end
    end

    class String < Literal
      def to_sql
        "'%s'" % escape(value)
      end
    end

    class Float < Literal; end

    class Integer < Literal; end
  end
end
