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
        Boolean :in_stock, default: false
        String :name, default: "John"
        Float  :price, default: 0
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
      # | in_stock              | boolean   | Boolean          |  false  |   Y   |  N  |  N  |
      # | name                  | string    | varchar(255)     |  John   |   Y   |  N  |  N  |
      # | price                 | float     | double precision |   0.0   |   Y   |  N  |  N  |
      # +-----------------------+-----------+------------------+---------+-------+-----+-----+
      OUTPUT

      AnnotateSequel::Model.schema_info(klass).should eq output
    end

    it "should support indexes" do
      pending
    end
  end
end
