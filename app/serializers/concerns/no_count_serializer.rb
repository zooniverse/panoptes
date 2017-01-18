module NoCountSerializer
  extend ActiveSupport::Concern

  module ClassMethods

    private

    def serialize_meta(page, options)
      current_page = page.current_page
      meta = {
          page: current_page,
          page_size: page.limit_value,
          count: 0,
          include: options.include,
          page_count: 0,
          previous_page: current_page - 1,
          next_page: current_page + 1
      }

      meta[:first_href] = page_href(1, options)
      meta[:previous_href] = page_href(meta[:previous_page], options)
      meta[:next_href] = page_href(meta[:next_page], options)
      meta[:last_href] = page_href(meta[:page_count], options)
      meta
    end
  end
end
