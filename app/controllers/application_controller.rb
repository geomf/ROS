# Portions Copyright (C) 2015 Intel Corporation

##
# This is base controller for each other controllers
#
class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.

  # protect_from_forgery with: :exception
  protect_from_forgery with: :null_session, if: proc { |c| c.request.format == 'application/json' }

  def api_call_handle_error
    yield
  rescue ActiveRecord::RecordNotFound => ex
    render :text => "", :status => :not_found
  rescue LibXML::XML::Error, ArgumentError => ex
    report_error ex.message, :bad_request
  rescue ActiveRecord::RecordInvalid => ex
    message = "#{ex.record.class} #{ex.record.id}: "
    ex.record.errors.each { |attr, msg| message << "#{attr}: #{msg} (#{ex.record[attr].inspect})" }
    report_error message, :bad_request
  rescue OSM::APIError => ex
    report_error ex.message, ex.status
  rescue AbstractController::ActionNotFound => ex
    raise
  rescue StandardError => ex
    logger.info("API threw unexpected #{ex.class} exception: #{ex.message}")
    ex.backtrace.each { |l| logger.info(l) }
    report_error "#{ex.class}: #{ex.message}", :internal_server_error
  end

  # Report and error to the user
  # (If anyone ever fixes Rails so it can set a http status "reason phrase",
  #  rather than only a status code and having the web engine make up a
  #  phrase from that, we can also put the error message into the status
  #  message. For now, rails won't let us)
  def report_error(message, status = :bad_request)
    # TODO: some sort of escaping of problem characters in the message
    response.headers["Error"] = message

    if request.headers["X-Error-Format"] &&
        request.headers["X-Error-Format"].casecmp("xml").zero?
      result = OSM::API.new.get_xml_doc
      result.root.name = "osmError"
      result.root << (XML::Node.new("status") << "#{Rack::Utils.status_code(status)} #{Rack::Utils::HTTP_STATUS_CODES[status]}")
      result.root << (XML::Node.new("message") << message)

      render :text => result.to_s, :content_type => "text/xml"
    else
      render :text => message, :status => status, :content_type => "text/plain"
    end
  end
end
