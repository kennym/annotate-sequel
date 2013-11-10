require 'spec_helper'

describe AnnotateSequel::Model do
  describe ".schema_info(klass)" do
    before(:each) do
      @DB = Sequel.sqlite
      @DB.create_table :items do
        primary_key :id
        String :name
        Float :price
      end
    end

    let(:klass) {
      class Item < Sequel::Model(:items)
      end
      Item
    }
    it "should return the model schema" do
      AnnotateSequel::Model.schema_info(klass).should eql(<<-EOS)
# Schema Info
# 
# Table name: items
# 
#  id :integer, {:allow_null=>false, :default=>nil, :primary_key=>true, :db_type=>"integer", :ruby_default=>nil}
#  name :string, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"varchar(255)", :ruby_default=>nil}
#  price :float, {:allow_null=>true, :default=>nil, :primary_key=>false, :db_type=>"double precision", :ruby_default=>nil}
# 
EOS
    end

    it "should support indexes"
  end
end
