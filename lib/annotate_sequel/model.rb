class AnnotateSequel
  COMPAT_PREFIX    = "== Schema Info"
  PATTERN          = /^\n?# (?:#{COMPAT_PREFIX}).*?\n(#.*\n)*\n*/
  module Model
    class << self
      def model_dir
        @model_dir || "app/models"
      end

      def model_dir=(dir)
        @model_dir = dir
      end

      def schema_info(klass)

        info = "# Schema Info\n"
        info << "# \n"
        info << "# Table name: #{klass.table_name}\n"
        info << "# \n"

        klass.db_schema.each do |key, value|
          type = value.delete(:type)
          info << "#  #{key} :#{type}, #{value}\n"
        end
        info << "# \n"
      end

      def get_model_files
        models = []
        begin
          Dir.chdir(@model_dir) do
            models = Dir["**/*.rb"]
          end
        rescue SystemCallError
          puts "No models found in directory '#{model_dir}'."
          exit 1
        end
        models
      end

      def get_model_class(file)
        model_path = file.gsub(/\.rb$/, '')
        get_loaded_model(model_path) || get_loaded_model(model_path.split("/").last)
      end

      def get_loaded_model(model_path)
        ObjectSpace.each_object(::Class).
          select do |c|
            Class === c and
            c.ancestors.respond_to?(:include?) and
            c.ancestors.include?(Sequel::Model)
          end
      end

      def annotate_model_file(annotated, file)
        begin
          klass = get_model_class(file)
          if klass && klass < Sequel::Model
            if annotate(klass, file)
              annotated << klass
            end
          end
        rescue Exception => e
          puts "Unable to annotate #{file}: #{e.message}"
          puts "\t" + e.backtrace.join("\n\t")
        end
      end

      def do_annotations
        annotated = []
        get_model_files.each do |file|
          annotate_model_file(annotated, file)
        end
        if annotated.empty?
          puts "Nothing annotated"
        else
          puts "Annotated (#{annotated.length}): #{annotated.join(', ')}"
        end
      end

      def annotate_one_file(file_name, info_block)
        if File.exist?(file_name)
          old_content = File.read(file_name)

          header_pattern = /(^# Table name:.*?\n(#.*[\r]?\n)*[\r]?)/
          old_header = old_content.match(header_pattern).to_s
          new_header = info_block.match(header_pattern).to_s

          column_pattern = /^#[\t ]+\w+[\t ]+.+$/
          old_columns = old_header && old_header.scan(column_pattern).sort
          new_columns = new_header && new_header.scan(column_pattern).sort
          if old_columns == new_columns
            return false
          end

          old_content.sub!(PATTERN, '')
          new_content = info_block + "\n" + old_content

          File.open(file_name, "wb") { |f| f.puts new_content }
          return true
        else
          return false
        end
      end

      def annotate(klass, file)
        begin
          info = schema_info(klass)
          did_annotate = false
          model_file_name = File.join(model_dir, file)
          
          if annotate_one_file(model_file_name, info)
            did_annotate = true
          end

          return did_annotate
        rescue Exception => e
          puts "Unable to annotate #{file}: #{e.message}"
        end
      end
    end
  end
end
