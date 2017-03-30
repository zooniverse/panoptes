module VirtualUpdatedAt
  refine PaperTrail::Version do
    def updated_at
      created_at
    end
  end
end
