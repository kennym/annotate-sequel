annotate_lib = File.expand_path(File.dirname(File.dirname(__FILE__)))

desc "Add schema information (as comments) to model files"
task :annotate_models => :environment do
  require "#{annotate_lib}/annotate_sequel/model"

  AnnotateSequel::Model.do_annotations
end
