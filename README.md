## sql-parser

A Ruby library for parsing and generating SQL statements.

### Features

* Parse arbitrary SQL strings into an AST (abstract syntax tree), which can
  then be traversed.

* Allows your code to understand and manipulate SQL in a deeper way than
  just using string manipulation.

### Usage

**Parsing a statement into an AST**

```ruby
>> require 'sql-parser'

# Build the AST from a SQL statement
>> select = SQLParser::Parser.parse('SELECT * FROM users WHERE id = 1')

# Output the expression as SQL
>> select.to_sql
=> "SELECT * FROM `users` WHERE `id` = 1"

# Drill down into the WHERE clause, to examine every piece
>> select.where_clause.to_sql
=> "WHERE `id` = 1"
>> select.where_clause.search_condition.to_sql
=> "`id` = 1"
>> select.where_clause.search_condition.left.to_sql
=> "`id`"
>> select.where_clause.search_condition.right.to_sql
=> "1"
```

**Manually building an AST**

```ruby
>> require 'sql-parser'

# Let's build a tree representing the SQL statement
# "SELECT * FROM users WHERE id = 1"

# First, the integer constant, "1"
>> integer_constant = SQLParser::Statement::Integer.new(1)

# Now the column reference, "id"
>> column_reference = SQLParser::Statement::Column.new('id')

# Now we'll combine the two using an equals operator, to create a search
# condition
>> search_condition = SQLParser::Statement::Equals.new(column_reference, integer_constant)

# Next we'll feed that search condition to a where clause
>> where_clause = SQLParser::Statement::WhereClause.new(search_condition)

# Next up is the FROM clause.  First we'll build a table reference
>> users = SQLParser::Statement::Table.new('users')

# Now we'll feed that table reference to a from clause
>> from_clause = SQLParser::Statement::FromClause.new(users)

# Now we need to represent the asterisk "*"
>> all = SQLParser::Statement::All.new
>> list = SQLParser::Statement::SelectList.new(all)

# Now we're ready to hand off these objects to a select statement
>> select_statement = SQLParser::Statement::Select.new(list, from_clause, where_clause)
>> select_statement.to_sql
=> "SELECT * FROM users WHERE id = 1"
```

### License

This software is released under the MIT license.
