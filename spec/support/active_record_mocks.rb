module RSpec
  module Helpers
    module ActiveRecordMocks
      def mock_active_record_model(name, &block)
        constant_instance(name).class_eval do
          self.primary_key = :id

          def self.table_name
            "__#{model_name.singular}"
          end

          def self.table_exists?
            true
          end
        end
        create_temp_table(name, &block)
      end

      def create_temp_table(table, &block)
        before :all do
          ActiveRecord::Migration.suppress_messages do
            ActiveRecord::Migration.create_table "__#{table}_table",
              :temporary => true do |t|

              block.call(t)
            end
          end
        end

        after :all do
          ActiveRecord::Migration.suppress_messages do
            ActiveRecord::Migration.drop_table "__#{table}_table"
          end
        end
      end

      private

      def constant_instance(name)
        table_name_const = "#{name}_table".camelize
        if const_defined?(table_name_const)
          Object.const_get(table_name_const)
        else
          const_instance = Class.new(ActiveRecord::Base)
          Object.const_set(table_name_const, const_instance)
        end
      end
    end
  end
end
