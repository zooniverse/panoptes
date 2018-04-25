class UserLanguages
  attr_reader :controller

  delegate :params, :api_user, :request, to: :controller

  def initialize(controller)
    @controller = controller
  end

  def ordered
    param_langs  = [ params[:language] ]
    user_langs   = user_accept_languages
    header_langs = parse_http_accept_languages
    ( param_langs | user_langs | header_langs ).compact
  end

  private

  def user_accept_languages
    api_user.try(:languages) || []
  end

  def parse_http_accept_languages
    language_extractor = AcceptLanguageExtractor.new(
      request.env['HTTP_ACCEPT_LANGUAGE']
    )

    language_extractor.parse_languages
  end
end
