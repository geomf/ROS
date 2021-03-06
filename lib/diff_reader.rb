# Portions Copyright (C) 2015 Intel Corporation

##
# DiffReader reads OSM diffs and applies them to the database.
class DiffReader
  attr_reader :changed_feeders

  MODELS = {
    'node' => PlanetOsmNode,
    'way' => PlanetOsmWay,
    'relation' => PlanetOsmRel
  }.freeze

  POSSIBLE_ACTIONS = %w(create modify delete).freeze

  def self.current
    RequestStore[:diff_reader]
  end

  ##
  # Construct a diff reader by giving it a bunch of XML +data+ to parse
  # in OsmChange format. All diffs must be limited to a single changeset
  # given in +changeset+.
  def initialize(data)
    @reader = XML::Reader.string(data)
    # document that's (re-)used to handle elements expanded out of the
    # diff processing stream.
    @doc = XML::Document.new
    @doc.root = XML::Node.new('osm')

    @changed_feeders = {}
  end

  ##
  # Reads the next element from the XML document. Checks the return value
  # and throws an exception if an error occurred.
  def read_or_die
    # NOTE: XML::Reader#read returns false for EOF and raises an
    # exception if an error occurs.
    @reader.read
  rescue LibXML::XML::Error => ex
    raise OSM::APIBadXMLError.new('changeset', xml, ex.message)
  end

  ##
  # An element-block mapping for using the LibXML reader interface.
  #
  # Since a lot of LibXML reader usage is boilerplate iteration through
  # elements, it would be better to DRY and do this in a block. This
  # could also help with error handling...?
  def with_element
    # if the start element is empty then don't do any processing, as
    # there won't be any child elements to process!
    unless @reader.empty_element?
      # read the first element
      read_or_die

      while @reader.node_type != LibXML::XML::Reader::TYPE_END_ELEMENT
        if @reader.node_type == LibXML::XML::Reader::TYPE_ELEMENT
          name = @reader.name

          yield name, attributes
        else
          read_or_die
        end
      end
    end
    read_or_die
  end

  def attributes
    attributes = {}
    if @reader.has_attributes?
      while @reader.move_to_next_attribute == 1
        attributes[@reader.name] = @reader.value
      end

      @reader.move_to_element
    end
    attributes
  end

  ##
  # An element-block mapping for using the LibXML reader interface.
  #
  # Since a lot of LibXML reader usage is boilerplate iteration through
  # elements, it would be better to DRY and do this in a block. This
  # could also help with error handling...?
  def with_model
    with_element do |model_name, _model_attributes|
      model = MODELS[model_name]
      fail OSM::APIBadUserInput, "Unexpected element type #{model_name}, expected node, way or relation." \
        if model.nil?

      # new in libxml-ruby >= 2, expand returns an element not associated
      # with a document. this means that there's no encoding parameter,
      # which means basically nothing works.
      expanded = @reader.expand

      # create a new, empty document to hold this expanded node
      new_node = @doc.import(expanded)
      @doc.root << new_node

      yield model, new_node
      @reader.next

      # remove element from doc - it will be garbage collected and the
      # rest of the document is re-used in the next iteration.
      @doc.root.child.remove!
    end
  end

  def commit
    # take the first element and check that it is an osmChange element
    @reader.read
    fail OSM::APIBadUserInput, "Document element should be 'osmChange'." \
      if @reader.name != 'osmChange'

    read_all_changes
    Renderer.current.send_dirty

    @changed_feeders
  end

  # loop at the top level, within the <osmChange> element
  def read_all_changes
    with_element do |action_name, _|
      # check weather action is possible, if not, it must be the users fault!
      fail OSM::APIChangesetActionInvalid, action_name unless action_name.in?(POSSIBLE_ACTIONS)

      method_hook = GeoRecord.method(action_name)
      with_model do |model, xml|
        id = read_and_validate_id(model, xml)
        method_hook.call(id, model, xml)
      end
    end
  end

  def read_and_validate_id(model, xml)
    fail OSM::APIBadXMLError.new(model, xml, 'ID is always required.') \
      if xml['id'].nil?

    Validator.read_int(xml['id'], 'ID')
  end
end
