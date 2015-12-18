module Translatable
  extend ActiveSupport::Concern

  included do
    validates :primary_language, format: {with: /\A[a-z]{2}(\z|-[A-z]{2})/}
    has_many content_association, autosave: true, inverse_of: name.downcase.to_sym
    can_be_linked content_model.name.underscore.to_sym, :scope_for, :translate, :user

    validates content_association, presence: true
  end

  module ClassMethods
    def content_association
      "#{model_name.singular}_contents".to_sym
    end

    def content_model
      "#{name}Content".constantize
    end

    def load_with_languages(query, languages=[])
      query = query.eager_load(content_association).joins(content_association)
      where_clause = "\"#{content_association}\".\"language\" = \"#{table_name}\".\"primary_language\""
      if !languages.empty?
        where_clause = "#{where_clause} OR \"#{content_association}\".\"language\" ~ ?"
        query.where(where_clause, lang_regex(languages))
      else
        query.where(where_clause)
      end
    end

    private

    def lang_regex(langs)
      langs = langs.map{ |lang| lang[0..1] }.uniq.join("|")
      "^(#{langs}).*"
    end
  end

  def content_for(languages)
    languages_to_sort = languages_to_sort(languages)
    if content_association.loaded?
      content = nil
      languages_to_sort.find do |lang|
        content = content_association.find { |c| c.language == lang }
      end
      content
    else
      load_content_from_db(languages_to_sort)
    end
  end

  def available_languages
    content_association.pluck(:language).map(&:downcase)
  end

  def content_association
    @content_association ||= send(self.class.content_association)
  end

  def primary_content
    @primary_content ||= if content_association.loaded?
      content_association.to_a.find do |content|
        content.language == primary_language
      end
    else
      content_association.find_by(language: primary_language)
    end
  end

  def load_content_from_db(languages_to_sort)
    join_values = languages_to_sort.each_with_index.reduce([]) do |values, (lang, i)|
      values << "('#{lang}',#{i})"
    end
    join_clause = "JOIN (VALUES #{join_values.join(",")}) as x(lang, ordering) "\
    "ON \"#{self.class.content_association}\".\"language\" = x.lang"
    content_association.where(language: languages_to_sort)
    .joins(join_clause)
    .order("x.ordering")
    .first
  end

  def languages_to_sort(languages)
    (Array.wrap(languages) | [primary_language]).flat_map do |lang|
      if lang.length == 2
        lang
      else
        [lang, lang[0..1]]
      end
    end.uniq
  end
end
