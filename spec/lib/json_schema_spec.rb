require 'spec_helper'

RSpec.describe JsonSchema do
  shared_examples "validates json" do
    context "valid json" do
      let(:valid_json) do
        {
          "id" => 1,
          "name" => "basdf"
        }
      end

      it 'should not raise an error' do
        expect do
          subject.validate!(valid_json)
        end.to_not raise_error
      end

      context "when allowing additional properties" do

        it 'should not raise an error' do
          expect do
            subject.validate!(valid_json)
          end.to_not raise_error
        end
      end

      context "when not allowing additional properties on the schema" do
        let(:non_aprops_schema) do
          Class.new(JsonSchema) do
            schema do
              type "object"
              additional_properties false
            end
          end.new
        end

        it "should format the error message with the schema root field name" do
          field_msg = "contains additional properties [\"invalid_property\"] outside of the schema when none are allowed"
          expect do
            non_aprops_schema.validate!({ "invalid_property" => "value" })
          end.to raise_error({ "schema" => field_msg }.to_s)
        end
      end
    end

    context "invalid json" do
      let(:invalid_json) do
        {
          "id" => 1,
          "name" => 4,
          "metadata" => {
            "end" => 10,
            "finish" => "at nine"
          }
        }
      end

      it 'should raise an error' do
        expect do
          subject.validate!(invalid_json)
        end.to raise_error(JsonSchema::ValidationError)
      end

      it 'should format the error message for use in the API response' do
        message = { "name" => "of type Fixnum did not match the following type: string",
                    "metadata" => "did not contain a required property of 'start'" }.to_s
        expect do
          subject.validate!(invalid_json)
        end.to raise_error(message)
      end
    end
  end

  describe "::schema" do
    subject do
      Class.new(JsonSchema) do
        schema do
          type "object"
          required "id", "name"

          property "id" do
            type "integer"
          end

          property "name" do
            type "string"
          end

          property "metadata" do
            type "object"
            required "start", "end"
            property "start" do
              type "integer"
            end

            property "end" do
              type "float"
            end
          end
        end
      end.new
    end

    it_behaves_like "validates json"
  end

  describe "::build" do
    subject do
      JsonSchema.build do
        type "object"
        required "id", "name"

        property "id" do
          type "integer"
        end

        property "name" do
          type "string"
        end

        property "metadata" do
          type "object"
          required "start", "end"

          property "start" do
            type "integer"
          end

          property "end" do
            type "float"
          end
        end
      end
    end

    it_behaves_like "validates json"
  end
end
