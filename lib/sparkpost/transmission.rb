require 'net/http'
require 'uri'
require_relative '../core_extensions/object'
require_relative 'request'
require_relative 'exceptions'

module SparkPost
  class Transmission
    include Request

    def initialize(api_key, api_host)
      @api_key = api_key
      @api_host = api_host
      @base_endpoint = "#{@api_host}/api/v1/transmissions"
    end

    def send_payload(data = {})
      # TODO: consider refactoring this into send_message in v2
      request(endpoint, @api_key, data)
    end

    def send_message(to, from, subject, html_message = nil, **options)
      # TODO: add validations for to, from
      html_message = content_from(options, :html) || html_message
      text_message = content_from(options, :text) || options[:text_message]
      template_id = content_from(options, :template_id)

      if html_message.blank? && text_message.blank? && template_id.blank?
        raise ArgumentError, 'Content missing. Either provide html_message or
         text_message or specify a valid template_id in options parameter'
      end

      options_from_args = {
        recipients: prepare_recipients(to),
        content: {
          from: from,
          subject: subject,
        },
        options: {}
      }

      if template_id.present?
        options_from_args[:content][:template_id] = template_id
      else
        options_from_args[:content][:html] = html_message if html_message.present?
        options_from_args[:content][:text] = text_message if text_message.prsent?
      end

      options.delete(:text_message)
      options.delete(:template_id)

      options.merge!(options_from_args) { |_k, opts, _args| opts }
      add_attachments(options)

      send_payload(options)
    end

    def prepare_recipients(recipients)
      recipients = [recipients] unless recipients.is_a?(Array)
      recipients.map { |recipient| prepare_recipient(recipient) }
    end

    private

    def add_attachments(options)
      if options[:attachments].present?
        options[:content][:attachments] = options.delete(:attachments)
      end
    end

    def prepare_recipient(recipient)
      if recipient.is_a?(Hash)
        raise ArgumentError,
              "email missing - '#{recipient.inspect}'" unless recipient[:email]
        { address: recipient }
      else
        { address: { email: recipient } }
      end
    end

    def content_from(options, key)
      (options || {}).fetch(:content, {}).fetch(key, nil)
    end
  end
end
