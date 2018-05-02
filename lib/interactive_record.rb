require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord

  # Class Methods
  def self.table_name
    self.to_s.downcase.pluralize
  end

  def self.column_names
    DB[:conn].results_as_hash = true
    sql = "pragma table_info('#{table_name}')"
    table = DB[:conn].execute(sql)

    column_names = []
    table.each do |row|
      column_names << row["name"]
    end
    column_names.compact
  end

  def self.find_by_name (name)
    sql = "SELECT * FROM #{self.table_name} WHERE name='#{name}'"
    DB[:conn].execute(sql)
  end

  def self.find_by(hash)
    value = hash.values.first
    formatted_value = value == Fixnum ? value : "'#{value}'"
    sql = "SELECT * FROM #{self.table_name} WHERE #{hash.keys.first}=#{formatted_value}"
    DB[:conn].execute(sql)
  end

  # Instance methods
  def initialize (options={})
    options.each { |attr, value| self.send("#{attr}=", value) }
  end

  def save ()
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  # Helper Instance Methods (should be private but test calls them)
  def col_names_for_insert
    self.class.column_names.delete_if {|col| col == "id"}.join(", ")
  end
  def values_for_insert
    values = []
    self.class.column_names.each do |col_name|
      # values has all attribute values except any set to nil
      values << "'#{send(col_name)}'" unless send(col_name).nil?
    end
    values.join(", ")
  end
  def table_name_for_insert
    self.class.table_name
  end

end
