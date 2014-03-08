require 'sequel'
require 'terminal-table'

Sequel.extension :inflector

class AnnotateSequel
  COMPAT_PREFIX = "== Schema Info"
  PATTERN       = /^\n?# (?:#{COMPAT_PREFIX}).*?\n(#.*\n)*\n*/

  module Model
    class << self
      def model_dir
        @model_dir || "app/models"
      end

      def model_dir=(dir)
        @model_dir = dir
      end

      def schema_info(klass)
        fks = process_fks(klass)

        table = Terminal::Table.new
        table.title = klass.table_name
        table.headings = ["Column", "Ruby Type", "DB Type", "Default", "Null?", "PK?", "FK?"]

        table.rows = klass.db_schema.map do |key, value|
          [ key,
            value[:type],
            value[:db_type],
            value[:ruby_default] || '-',
            value[:allow_null]  ? 'Y' : 'N',
            value[:primary_key] ? 'Y' : 'N',
            fks.include?(key)   ? 'Y' : 'N'
          ]
        end

        # Align to the center the columns:
        # Default, Null?, PK? and FK?
        for i in 3..6
          table.align_column(i, :center)
        end

        # Comment the table
        output = String.new
        table.to_s.each_line { |line| output << "# #{line}" }

        output << "\n\n"
      end

      def process_fks(model)
        model.db.foreign_key_list(:items).map do |x|
          x[:columns]
        end.flatten
      end

      def get_model_files
        models = []
        begin
          Dir.chdir(model_dir) do
            models = Dir["**/*.rb"]
          end
        rescue SystemCallError
          puts "No models found in directory '#{model_dir}'."
          exit 1
        end
        models
      end

      def get_model_class(file)
        require File.expand_path("#{model_dir}/#{file}")
        model_path = file.gsub(/\.rb$/, '')
        get_loaded_model(model_path) || get_loaded_model(model_path.split("/").last)
      end

      def get_loaded_model(model_path)
        ObjectSpace.each_object(::Class).
          select do |c|
            Class === c and
            c.ancestors.respond_to?(:include?) and
            c.ancestors.include?(Sequel::Model)
          end.
          detect { |c| c.name.demodulize.underscore == model_path }
      end

      def annotate_model_file(annotated, file)
        begin
          klass = get_model_class(file)
          if klass && klass < Sequel::Model
            if annotate(klass, file)
              annotated << klass.to_s.demodulize
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
          pattern = /^#\s[\+\|].+[\+\|]\n*/

          return false if old_content.scan(pattern).join == info_block

          File.open(file_name, "wb") do |f|
            f.puts info_block + old_content.gsub(pattern, '')
          end

          return true
        end

        false
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
