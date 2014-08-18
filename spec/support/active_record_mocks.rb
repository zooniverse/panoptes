module RSpec
  module Helpers
    module ActiveRecordMocks
      def mock_active_record_model(name, &block)
        Object.const_set("#{name}_table".camelize,
                         Class.new(ActiveRecord::Base)).class_eval do

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
        p table
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
    end
  end
end
