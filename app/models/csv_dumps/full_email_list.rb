module CsvDumps
  class FullEmailList < DumpScope
    EXPORT_FIELDS = {global: :global_email_communication,
                     beta: :beta_email_communication}.freeze

    def initialize(type)
      @type = type
    end

    def each
      user_emails.find_each do |user|
        yield user
      end
    end

    def user_emails
      emailable_users.select(:id, :email, export_field)
    end

    def emailable_users
      @emailable_users ||= User
                             .active
                             .where(valid_email: true)
                             .where(export_field => true)
    end

    def export_field
      EXPORT_FIELDS.fetch(@type)
    end
  end
end
