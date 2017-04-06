module OrderedLocations

  def ordered_locations
    if locations.loaded?
      if locations.all? { |loc| loc.metadata&.key?("index") }
        locations.sort_by { |loc| loc.metadata["index"] }
      else
        locations
      end
    else
      locations.order("\"media\".\"metadata\"->'index' ASC")
    end
  end
end
