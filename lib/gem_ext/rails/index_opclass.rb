require 'active_record/connection_adapters/abstract/schema_statements'
require 'active_record/connection_adapters/abstract_adapter'
require 'active_record/connection_adapters/postgresql/schema_statements'
require 'active_record/connection_adapters/postgresql_adapter'
require 'active_record/schema_dumper'

# Backported from Rails 5.0 patch at https://github.com/rails/rails/pull/18499

ActiveRecord::ConnectionAdapters::IndexDefinition.class_eval do
  attr_accessor :opclasses, :collations, :nulls

  def initialize(*args)
    @opclasses, @collations, @nulls = args[-3..-1]
    super(*args[0..-4])
  end
end

ActiveRecord::ConnectionAdapters::SchemaStatements.module_eval do
  def add_index_options(table_name, column_name, options = {}) #:nodoc:
    column_names = Array(column_name)
    index_name   = index_name(table_name, column: column_names)

    options.assert_valid_keys(:unique, :order, :name, :where, :length, :internal, :using, :algorithm, :type, :opclass, :collate, :nulls)

    index_type = options[:unique] ? "UNIQUE" : ""
    index_type = options[:type].to_s if options.key?(:type)
    index_name = options[:name].to_s if options.key?(:name)
    max_index_length = options.fetch(:internal, false) ? index_name_length : allowed_index_name_length

    if options.key?(:algorithm)
      algorithm = index_algorithms.fetch(options[:algorithm]) {
        raise ArgumentError.new("Algorithm must be one of the following: #{index_algorithms.keys.map(&:inspect).join(', ')}")
      }
    end

    using = "USING #{options[:using]}" if options[:using].present?

    if supports_partial_index?
      index_options = options[:where] ? " WHERE #{options[:where]}" : ""
    end

    if index_name.length > max_index_length
      raise ArgumentError, "Index name '#{index_name}' on table '#{table_name}' is too long; the limit is #{max_index_length} characters"
    end
    if table_exists?(table_name) && index_name_exists?(table_name, index_name, false)
      raise ArgumentError, "Index name '#{index_name}' on table '#{table_name}' already exists"
    end
    index_columns = quoted_columns_for_index(column_names, options).join(", ")

    [index_name, index_type, index_columns, index_options, algorithm, using]
  end

  def add_index_length(option_strings, column_names, options = {})
    if options.is_a?(Hash) && length = options[:length]
      case length
      when Hash
        column_names.each {|name| option_strings[name] += "(#{length[name]})" if length.has_key?(name) && length[name].present?}
      when Fixnum
        column_names.each {|name| option_strings[name] += "(#{length})"}
      end
    end

    option_strings
  end

  def add_index_collation(option_strings, column_names, options = {})
    if options.is_a?(Hash) && collation = options[:collate]
      case collation
      when Hash
        column_names.each {|name| option_strings[name] += " COLLATE #{quote_column_name(collation[name])}" if collation.has_key?(name)}
      when String, Symbol
        column_names.each {|name| option_strings[name] += " COLLATE #{quote_column_name(collation)}"}
      end
    end

    option_strings
  end

  def add_index_operator_class(option_strings, column_names, options = {})
    if options.is_a?(Hash) && opclass = options[:opclass]
      case opclass
      when Hash
        column_names.each {|name| option_strings[name] += " #{opclass[name]}" if opclass.has_key?(name)}
      when String, Symbol
        column_names.each {|name| option_strings[name] += " #{opclass}"}
      end
    end

    option_strings
  end

  def add_index_sort_order(option_strings, column_names, options = {})
    if options.is_a?(Hash) && order = options[:order]
      case order
      when Hash
        column_names.each {|name| option_strings[name] += " #{order[name].upcase}" if order.has_key?(name)}
      when String, Symbol
        column_names.each {|name| option_strings[name] += " #{order.upcase}"}
      end
    end

    option_strings
  end

  def add_index_null_order(option_strings, column_names, options = {})
    if options.is_a?(Hash) && order = options[:nulls]
      case order
      when Hash
        column_names.each {|name| option_strings[name] += " NULLS #{order[name].upcase}" if order.has_key?(name)}
      when String, Symbol
        column_names.each {|name| option_strings[name] += " NULLS #{order.upcase}"}
      end
    end

    option_strings
  end

  # Overridden by the MySQL adapter for supporting index lengths
  def quoted_columns_for_index(column_names, options = {})
    option_strings = Hash[column_names.map {|name| [name, '']}]

    if supports_index_length?
      option_strings = add_index_length(option_strings, column_names, options)
    end

    if supports_index_collation?
      option_strings = add_index_collation(option_strings, column_names, options)
    end

    if supports_index_operator_class?
      option_strings = add_index_operator_class(option_strings, column_names, options)
    end

    if supports_index_sort_order?
      option_strings = add_index_sort_order(option_strings, column_names, options)
    end

    if supports_index_null_order?
      option_strings = add_index_null_order(option_strings, column_names, options)
    end

    column_names.map {|name| quote_column_name(name) + option_strings[name]}
  end

  def options_include_default?(options)
    options.include?(:default) && !(options[:null] == false && options[:default].nil?)
  end

  def index_name_for_remove(table_name, options = {})
    index_name = index_name(table_name, options)

    unless index_name_exists?(table_name, index_name, true)
      if options.is_a?(Hash) && options.has_key?(:name)
        options_without_column = options.dup
        options_without_column.delete :column
        index_name_without_column = index_name(table_name, options_without_column)

        return index_name_without_column if index_name_exists?(table_name, index_name_without_column, false)
      end

      raise ArgumentError, "Index name '#{index_name}' on table '#{table_name}' does not exist"
    end

    index_name
  end

  def rename_table_indexes(table_name, new_name)
    indexes(new_name).each do |index|
      generated_index_name = index_name(table_name, column: index.columns)
      if generated_index_name == index.name
        rename_index new_name, generated_index_name, index_name(new_name, column: index.columns)
      end
    end
  end

  def rename_column_indexes(table_name, column_name, new_column_name)
    column_name, new_column_name = column_name.to_s, new_column_name.to_s
    indexes(table_name).each do |index|
      next unless index.columns.include?(new_column_name)
      old_columns = index.columns.dup
      old_columns[old_columns.index(new_column_name)] = column_name
      generated_index_name = index_name(table_name, column: old_columns)
      if generated_index_name == index.name
        rename_index table_name, generated_index_name, index_name(table_name, column: index.columns)
      end
    end
  end
end

ActiveRecord::ConnectionAdapters::AbstractAdapter.class_eval do
  # Does this adapter support index length?
  def supports_index_length?
    false
  end

  # Does this adapter support index operator class?
  def supports_index_operator_class?
    false
  end

  # Does this adapter support index collation?
  def supports_index_collation?
    false
  end

  # Does this adapter support index null order?
  def supports_index_null_order?
    false
  end
end

ActiveRecord::ConnectionAdapters::PostgreSQL::SchemaStatements.module_eval do
  # Returns an array of indexes for the given table.
  def indexes(table_name, name = nil)
    result = query(<<-SQL, 'SCHEMA')
             SELECT distinct i.relname, d.indisunique, d.indkey, pg_get_indexdef(d.indexrelid), t.oid
             FROM pg_class t
             INNER JOIN pg_index d ON t.oid = d.indrelid
             INNER JOIN pg_class i ON d.indexrelid = i.oid
             WHERE i.relkind = 'i'
               AND d.indisprimary = 'f'
               AND t.relname = '#{table_name}'
               AND i.relnamespace IN (SELECT oid FROM pg_namespace WHERE nspname = ANY (current_schemas(false)) )
            ORDER BY i.relname
          SQL

    result.map do |row|
      index_name = row[0]
      unique = row[1] == 't'
      indkey = row[2].split(" ")
      inddef = row[3]
      oid = row[4]

      columns = Hash[query(<<-SQL, "SCHEMA")]
            SELECT a.attnum, a.attname
            FROM pg_attribute a
            WHERE a.attrelid = #{oid}
            AND a.attnum IN (#{indkey.join(",")})
            SQL

      column_names = columns.values_at(*indkey).compact

      unless column_names.empty?
        matching_braces = /(?=\(((?:[^()]++|\(\g<1>\))++)\))/
        # the column definitions are inside the first pair of braces
        coldefs = inddef.scan(matching_braces).flatten[0]

        coldef_parser = %r{
        (?<expr>[^\(]*\(.*\)|[^" ]+|"(?:[^"]|"")+")
        (?:\ COLLATE\ "(?<collation>(?:[^"]|"")+)")?
        (?:\ (?<opclass>[a-z0-9_]+_ops))?
        (?:\ (?<order>ASC|DESC))?
        (?:\ NULLS\ (?<nulls>FIRST|LAST))?
        (?:,|$)
        }x

        collations = {}
        opclasses = {}
        orders = {}
        nulls = {}

        coldefs.scan(coldef_parser) do match = $~
          column = match[:expr].gsub('""', '"')
          next unless column_names.include? column # skip expressions (indkey 0)
          collations[column] = match[:collation].gsub('""', '"') if match[:collation]
          opclasses[column] = match[:opclass].to_sym if match[:opclass]
          orders[column] = match[:order].downcase.to_sym if match[:order]
          nulls[column] = match[:nulls].downcase.to_sym if match[:nulls]
        end

        where = inddef.scan(/WHERE (.+)$/).flatten[0]
        using = inddef.scan(/USING (.+?) /).flatten[0].to_sym

        ActiveRecord::ConnectionAdapters::IndexDefinition.new(table_name, index_name, unique, column_names, [], orders, where, nil, using, opclasses, collations, nulls)
      end
    end.compact
  end
end

ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.class_eval do
  def supports_index_collation?
    postgresql_version >= 90100
  end

  def supports_index_operator_class?
    true
  end

  def supports_index_sort_order?
    postgresql_version >= 80300
  end

  def supports_index_null_order?
    postgresql_version >= 80300
  end
end

ActiveRecord::SchemaDumper.class_eval do
  def indexes(table, stream)
    if (indexes = @connection.indexes(table)).any?
      add_index_statements = indexes.map do |index|
        statement_parts = [
                           "add_index #{remove_prefix_and_suffix(index.table).inspect}",
                           index.columns.inspect,
                           "name: #{index.name.inspect}"
                          ]
        statement_parts << 'unique: true' if index.unique

        statement_parts << "length: #{index.lengths.inspect}" if index.lengths.present?
        statement_parts << "order: #{index.orders.inspect}" if index.orders.present?
        statement_parts << "where: #{index.where.inspect}" if index.where
        statement_parts << "using: #{index.using.inspect}" if index.using
        statement_parts << "type: #{index.type.inspect}" if index.type
        statement_parts << "opclass: #{index.opclasses.inspect}" if index.opclasses.present?
        statement_parts << "collate: #{index.collations.inspect}" if index.collations.present?
        statement_parts << "nulls: #{index.nulls.inspect}" if index.nulls.present?

        "  #{statement_parts.join(', ')}"
      end

      stream.puts add_index_statements.sort.join("\n")
      stream.puts
    end
  end
end

