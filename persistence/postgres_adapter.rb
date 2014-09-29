require "sequel"
Sequel.extension :pg_hstore, :pg_hstore_ops

class PostgresAdapter
  def initialize(config:)
    @config = config
    @db = Sequel.connect(uri)
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

  def schema(namespace)
    Schema.new(db.schema(namespace))
  end

  class Schema
    def initialize(column_data)
      @column_data = column_data
    end

    def column_type(column_name)
      field_attributes(column_name).fetch(:db_type)
    end

  private

    attr_reader :column_data

    def field_attributes(field)
      column_data.select { |key, data| key == field }.flatten.last
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
