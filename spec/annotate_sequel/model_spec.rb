require 'spec_helper'

describe AnnotateSequel::Model do
  describe ".schema_info(klass)" do
    before(:all) do
      @DB = Sequel.sqlite
      @DB.create_table :items do
        primary_key :id
        foreign_key :category_id, :categories, null: false
        foreign_key [:manufacturer_name, :manufacturer_location], :manufacturers

        String :manufacturer_name, size: 50
        String :manufacturer_location
        String :name, default: "John"
        Float  :price, default: 0

        index [:manufacturer_name, :manufacturer_location], :name=>:name, :unique=>true
        index [:manufacturer_name], :name=>:manufacturer_name
      end
    end

    let(:klass) {
      class Item < Sequel::Model(:items)
      end
      Item
    }

    it "should return the model schema" do
      output = <<-OUTPUT.gsub(/^\s*/, '') << "\n"
      # +-----------------------+-----------+------------------+---------+-------+-----+-----+
      # |                                       items                                        |
      # +-----------------------+-----------+------------------+---------+-------+-----+-----+
      # | Column                | Ruby Type | DB Type          | Default | Null? | PK? | FK? |
      # +-----------------------+-----------+------------------+---------+-------+-----+-----+
      # | id                    | integer   | integer          |    -    |   N   |  Y  |  N  |
      # | category_id           | integer   | integer          |    -    |   N   |  N  |  Y  |
      # | manufacturer_name     | string    | varchar(50)      |    -    |   Y   |  N  |  Y  |
      # | manufacturer_location | string    | varchar(255)     |    -    |   Y   |  N  |  Y  |
      # | name                  | string    | varchar(255)     |  John   |   Y   |  N  |  N  |
      # | price                 | float     | double precision |   0.0   |   Y   |  N  |  N  |
      # +-----------------------+-----------+------------------+---------+-------+-----+-----+
      # +-------------------+------------------------------------------+---------+
      # |                                Indexes                                 |
      # +-------------------+------------------------------------------+---------+
      # | Name              | Columns                                  | Unique? |
      # +-------------------+------------------------------------------+---------+
      # | manufacturer_name | manufacturer_name                        | false   |
      # | name              | manufacturer_name, manufacturer_location | true    |
      # +-------------------+------------------------------------------+---------+
      OUTPUT

      AnnotateSequel::Model.schema_info(klass).should eq output
    end

    it "should support indexes" do
      # currently adding tests to the main test itself..
      pending
    end
  end
end
