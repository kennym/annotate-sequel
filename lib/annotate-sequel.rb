$:.unshift(File.dirname(__FILE__))

require 'annotate_sequel/version'
require 'annotate_sequel/model'

module Annotate
  def self.loaded_tasks=(val); @loaded_tasks = val; end
  def self.loaded_tasks; return @loaded_tasks; end

  def self.load_tasks
    return if(self.loaded_tasks)
    self.loaded_tasks = true
    Dir[File.join(File.dirname(__FILE__), 'tasks', '**/*.rake')].each { |rake| load rake }
  end

  def self.bootstrap_rake
    if File.exists?("./Rakefile")
      load "./Rakefile"
    end
    Rake::Task[:environment].invoke rescue nil
    self.load_tasks
  end
end
