require 'sequel'
require 'terminal-table'

Sequel.extension :inflector

class AnnotateSequel
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

        indexes = process_indexes(klass)

        if indexes.any?
          output << "\n"
          index_tbl = Terminal::Table.new
          index_tbl.title = "Indexes"
          index_tbl.headings = ["Name", "Columns", "Unique?"]
          index_tbl.rows = indexes
          index_tbl.to_s.each_line { |line| output << "# #{line}" }
        end
        output << "\n\n"
      end

      def process_indexes(model)
        model.db.indexes(model.table_name).map do |name, index|
          [name, index[:columns].join(", "), index[:unique]]
        end
      end

      # following this format from i think mysql
      # UNIQUE KEY `country` (`country`,`tag`)
      # KEY `index_histories_user` (`user_id`)
      def process_index(name, index)

        if index[:unique]
          "UNIQUE INDEX '#{name}' ('#{index[:columns].join("', '")}')"
        else
          "INDEX '#{name}' ('#{index[:columns].join("', '")}')"
        end
      end

      def process_fks(model)
        model.db.foreign_key_list(model.table_name).map do |x|
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
          detect { |c| c.name && c.name.demodulize.underscore == model_path }
      end

      def annotate_model_file(annotated, file)
        begin
          klass = get_model_class(file)
          if klass && annotate(klass, file)
            annotated << klass.to_s.demodulize
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

        puts annotated.empty? ?
          "Nothing annotated" :
          "Annotated (#{annotated.length}): #{annotated.join(', ')}"
      end

      def annotate_one_file(file_name, info_block)
        if File.exist?(file_name)
          current = File.read(file_name)
          pattern = /^#\s[\+\|].+[\+\|]\n*/

          return false if current.scan(pattern).join == info_block

          File.open(file_name, "wb") do |f|
            f.puts info_block + current.gsub(pattern, '')
          end

          true
        else
          false
        end
      end

      def annotate(klass, file)
        begin
          model_file_name = File.join(model_dir, file)
          annotate_one_file model_file_name, schema_info(klass)
        rescue Exception => e
          puts "Unable to annotate #{file}: #{e.message}"
        end
      end
    end
  end
end
