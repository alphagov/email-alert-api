require "sequel"
Sequel.extension :pg_hstore, :pg_hstore_ops
Sequel.default_timezone = :utc

class PostgresAdapter
  def initialize(config:)
    @config = config
    @db = Sequel.connect(uri)
  end

  def all(table_name)
    db[table_name].all
  end

  def find_by(table_name, key, values)
    prepared_values = Sequel.hstore(values)
    db[table_name].where(key => prepared_values)
  end

  def store(table_name, id, attributes)
    db[table_name].insert({id: id}.merge(
      HashToRowMapper.new(schema(table_name), attributes)
    ))
  end

  def clear
    data_tables.each do |table_identifier|
      db[table_identifier].truncate
    end
  end

private
  attr_reader(
    :config,
    :db,
  )

  def uri
    "postgres://%{host}/%{database}?user=%{user}&password=%{password}" % config
  end

  def data_tables
    db.tables - [:schema_migrations]
  end

  def schema(table_name)
    Schema.new(table_name, db.schema(table_name))
  end

  class Schema
    def initialize(table_name, column_data)
      @table_name = table_name
      @column_data = column_data
    end

    def column_type(column_name)
      column_attributes(column_name).fetch(:db_type)
    end

  private

    attr_reader :table_name, :column_data

    class ColumnNotFound < StandardError
      def initialize(table_name, column)
        @message = "Table `#{table_name}` does not have column `#{column}`"
      end

      attr_reader :message
    end

    def column_attributes(desired_column_name)
      column_data
        .select { |name, _data| name == desired_column_name }
        .fetch(0) { raise ColumnNotFound.new(table_name, desired_column_name) }
        .fetch(1)
    end
  end

  class HashToRowMapper
    def initialize(schema, row)
      @schema = schema
      @row = row
    end

    def to_hash
      row.reduce({}) { |result, (key, value)|
        result.merge(key => coerce(key, value))
      }
    end

  private
    attr_reader :schema, :row

    def coerce(key, value)
      coercion_for_type(
        schema.column_type(key)
      ).call(value)
    end

    def coercion_for_type(key)
      {
        "hstore" => Sequel.method(:hstore)
      }.fetch(key, identity_function)
    end

    def identity_function
      ->(x) { x }
    end
  end
end
