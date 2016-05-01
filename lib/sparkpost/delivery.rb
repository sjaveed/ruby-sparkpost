module SparkPost
  # == Sending Email with SparkPost
  #
  # Mail allows you to send emails using SparkPost's REST API.  This allows Rails
  # apps to continue to use ActionMailer while using the superior features of a
  # RESTful email delivery API
  #
  # === Sending via RESTful API
  #
  #   Mail.defaults do
  #     delivery_method SparkPost, {
  #       api_key: 'XXX'
  #     }
  #
  # === Delivering the email
  #
  # Once you have the settings right, sending the email is done by:
  #
  #   Mail.deliver do
  #     to 'mikel@test.lindsaar.net'
  #     from 'ada@test.lindsaar.net'
  #     subject 'testing sendmail'
  #     body 'testing sendmail'
  #   end
  #
  # Or by calling deliver on a Mail message
  #
  #   mail = Mail.new do
  #     to 'mikel@test.lindsaar.net'
  #     from 'ada@test.lindsaar.net'
  #     subject 'testing sendmail'
  #     body 'testing sendmail'
  #   end
  #
  #   mail.deliver!
  class Delivery
    # include Mail::CheckDeliveryParams

    def initialize(values)
      self.settings = {
          api_key: nil,
          perform_deliveries: true
      }.merge!(values)
    end

    attr_accessor :settings

    # Send the message via SparkPost.
    # The from and to attributes are optional. If not set, they are retrieve from the Message.
    def deliver!(mail)
      substitution_variables = {}

      mail['X-SP-MergeVars'].each do |h|
        substitution_variables.merge!(JSON.parse(h.value))
      end

      template_id = mail['X-SP-Template']

      from_address, to_address = mail.smtp_envelope_from, mail.smtp_envelope_to

      message_subject, message_body = mail.subject, mail.body.to_s
      message_body = nil unless message_body.present?

      unless self.settings[:perform_deliveries]
        to_address.map! { |a| a += '.sink.sparkpostmail.com' }
      end

      sparkpost_options = {
          content: {
              template_id: template_id
          },
          substitution_variables: substitution_variables
      }

      sparkpost_options[:content].delete(:template_id) if template_id.blank?

      client.transmission.send_message(to_address, from_address, message_subject, message_body, sparkpost_options)
    end

    private

    def client
      @client ||= SparkPost::Client.new(self.settings[:api_key])
    end
  end
end
