require_dependency 'email/sender'
require_dependency 'email/message_builder'

module Jobs

  # Asynchronously send an email to a user
  class UserEmailCustom < Jobs::Base

    def execute(args)
      raise Discourse::InvalidParameters.new(:subject) unless args[:subject].present?
      raise Discourse::InvalidParameters.new(:body) unless args[:body].present?
      raise Discourse::InvalidParameters.new(:type) unless args[:type].present?
      raise Discourse::InvalidParameters.new(:user_id) unless args[:user_id].present?

      type = args[:type]
      user = User.find_by(id: args[:user_id])

      message = EmailAll::Mailer.send_email(user.email, args)

      Email::Sender.new(message, type, user).send
    end

    sidekiq_retry_in do |count, exception|
      # retry in an hour when SMTP server is busy
      # or use default sidekiq retry formula
      case exception.wrapped
      when Net::SMTPServerBusy
        1.hour + (rand(30) * (count + 1))
      else
        Jobs::UserEmailCustom.seconds_to_delay(count)
      end
    end

    # extracted from sidekiq
    def self.seconds_to_delay(count)
      (count ** 4) + 15 + (rand(30) * (count + 1))
    end

  end

end
