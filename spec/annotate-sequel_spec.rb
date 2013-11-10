require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "AnnotateSequel" do
  it "should have a version" do
    AnnotateSequel::Version::STRING.should be_instance_of(String)
  end
end
