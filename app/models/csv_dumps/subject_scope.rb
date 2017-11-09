module CsvDumps
  class SubjectScope < DumpScope
    def each
      read_from_database do
        project_subjects.find_each do |subject|
          yield subject
        end
      end
    end

    private

    def project_subjects
      Subject
        .joins(:subject_sets)
        .eager_load(:subject_sets, :locations)
        .merge(resource.subject_sets)
    end
  end
end
