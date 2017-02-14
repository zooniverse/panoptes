class SubjectSelector
  def self.for(workflow)
    case strategy_for(workflow)
    when :cellect
      Subjects::CellectSelector.new(workflow)
    when :cellect_ex
      Subjects::CellectExSelector.new(workflow)
    else
      Subjects::BuiltInSelector.new(workflow)
    end
  end

  def self.strategy_for(workflow)
    case
    when workflow.subject_selection_strategy == "cellect"
      :cellect
    when workflow.subject_selection_strategy == "cellect_ex"
      :cellect_ex
    when workflow.using_cellect?
      :cellect
    else
      nil
    end
  end
end
