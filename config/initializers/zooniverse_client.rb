module ZooniverseClient
  URL = "http://zooniverse.org"

  def self.generate_url(query_params)
    "#{URL}/?#{query_params}"
  end
end
