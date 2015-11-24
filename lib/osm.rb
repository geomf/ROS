# The OSM module provides support functions for OSM.
module OSM
  require 'xml/libxml'

  # The base class for API Errors.
  class APIError < RuntimeError
    def status
      :internal_server_error
    end

    # noinspection RubyQuotedStringsInspection
    def to_s
      'Generic API Error'
    end
  end

  # Raised when access is denied.
  class APIAccessDenied < RuntimeError
    def status
      :forbidden
    end

    # noinspection RubyQuotedStringsInspection
    def to_s
      'Access denied'
    end
  end

  # Raised when an API object is not found.
  class APINotFoundError < APIError
    def status
      :not_found
    end

    # noinspection RubyQuotedStringsInspection
    def to_s
      'Object not found'
    end
  end

  # Raised when a precondition to an API action fails sanity check.
  class APIPreconditionFailedError < APIError
    # noinspection RubyQuotedStringsInspection
    def initialize(message = '')
      @message = message
    end

    def status
      :precondition_failed
    end

    def to_s
      "Precondition failed: #{@message}"
    end
  end

  # Raised when to delete an already-deleted object.
  class APIAlreadyDeletedError < APIError
    # noinspection RubyQuotedStringsInspection,RubyQuotedStringsInspection
    def initialize(object = 'object', object_id = '')
      @object = object
      @object_id = object_id
    end

    attr_reader :object, :object_id

    def status
      :gone
    end

    def to_s
      "The #{object} with the id #{object_id} has already been deleted"
    end
  end

  # Raised when a diff upload has an unknown action. You can only have create,
  # modify, or delete
  class APIChangesetActionInvalid < APIError
    def initialize(provided)
      @provided = provided
    end

    def status
      :bad_request
    end

    def to_s
      "Unknown action #{@provided}, choices are create, modify, delete"
    end
  end

  # Raised when bad XML is encountered which stops things parsing as
  # they should.
  class APIBadXMLError < APIError
    # noinspection RubyQuotedStringsInspection
    def initialize(model, xml, message = '')
      @model = model
      @xml = xml
      @message = message
    end

    def status
      :bad_request
    end

    def to_s
      "Cannot parse valid #{@model} from xml string #{@xml}. #{@message}"
    end
  end

  # raised when a two tags have a duplicate key string in an element.
  # this is now forbidden by the API.
  class APIDuplicateTagsError < APIError
    def initialize(type, id, tag_key)
      @type = type
      @id = id
      @tag_key = tag_key
    end

    attr_reader :type, :id, :tag_key

    def status
      :bad_request
    end

    def to_s
      "Element #{@type}/#{@id} has duplicate tags with key #{@tag_key}"
    end
  end

  # Raised when a way has more than the configured number of way nodes.
  # This prevents ways from being to long and difficult to work with
  class APITooManyWayNodesError < APIError
    def initialize(id, provided, max)
      @id = id
      @provided = provided
      @max = max
    end

    attr_reader :id, :provided, :max

    def status
      :bad_request
    end

    def to_s
      "You tried to add #{provided} nodes to way #{id}, however only #{max} are allowed"
    end
  end

  ##
  # raised when user input couldn't be parsed
  class APIBadUserInput < APIError
    def initialize(message)
      @message = message
    end

    def status
      :bad_request
    end

    def to_s
      @message
    end
  end

  ##
  # raised when bounding box is invalid
  class APIBadBoundingBox < APIError
    def initialize(message)
      @message = message
    end

    def status
      :bad_request
    end

    def to_s
      @message
    end
  end

  ##
  # raised when an API call is made using a method not supported on that URI
  class APIBadMethodError < APIError
    def initialize(supported_method)
      @supported_method = supported_method
    end

    def status
      :method_not_allowed
    end

    def to_s
      "Only method #{@supported_method} is supported on this URI"
    end
  end

  ##
  # raised when an API call takes too long
  class APITimeoutError < APIError
    def status
      :request_timeout
    end

    # noinspection RubyQuotedStringsInspection
    def to_s
      'Request timed out'
    end
  end

  class API
    # noinspection RubyQuotedStringsInspection,RubyQuotedStringsInspection,RubyQuotedStringsInspection,RubyQuotedStringsInspection,RubyQuotedStringsInspection,RubyQuotedStringsInspection
    def create_xml_doc
      doc = XML::Document.new
      doc.encoding = XML::Encoding::UTF_8
      root = XML::Node.new 'osm'
      # root['version'] = API_VERSION.to_s
      # root['generator'] = GENERATOR
      # root['copyright'] = COPYRIGHT_OWNER
      # root['license'] = LICENSE_URL

      doc.root = root
      doc
    end
  end
end
