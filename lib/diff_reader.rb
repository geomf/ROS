# Portions Copyright (C) 2015 Intel Corporation

##
# DiffReader reads OSM diffs and applies them to the database.
class DiffReader
  MODELS = {
    'node' => PlanetOsmNode,
    'way' => PlanetOsmWay,
    'relation' => PlanetOsmRel
  }

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

      while @reader.node_type != 15 # end element
        # because we read elements in DOM-style to reuse their DOM
        # parsing code, we don't always read an element on each pass
        # as the call to @reader.next in the innermost loop will take
        # care of that for us.
        if @reader.node_type == 1 # element
          name = @reader.name
          attributes = {}

          if @reader.has_attributes?
            while @reader.move_to_next_attribute == 1
              attributes[@reader.name] = @reader.value
            end

            @reader.move_to_element
          end

          yield name, attributes
        else
          read_or_die
        end
      end
    end
    read_or_die
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
      fail OSM::APIBadUserInput.new("Unexpected element type #{model_name}, expected node, way or relation.") if model.nil?
      # new in libxml-ruby >= 2, expand returns an element not associated
      # with a document. this means that there's no encoding parameter,
      # which means basically nothing works.
      expanded = @reader.expand

      # create a new, empty document to hold this expanded node
      new_node = @doc.import(expanded)
      @doc.root << new_node

      yield model, model_name, new_node
      @reader.next

      # remove element from doc - it will be garbage collected and the
      # rest of the document is re-used in the next iteration.
      @doc.root.child.remove!
    end
  end

  def commit
    # data structure used for mapping placeholder IDs to real IDs
    $ids = { node: {}, way: {}, relation: {} }

    # take the first element and check that it is an osmChange element
    @reader.read
    fail OSM::APIBadUserInput.new("Document element should be 'osmChange'.") if @reader.name != 'osmChange'

    # loop at the top level, within the <osmChange> element
    with_element do |action_name, _|
      case action_name
      when 'create'
        create_element
      when 'modify'
        modify_element
      when 'delete'
        delete_element
      else
        # no other actions to choose from, so it must be the users fault!
        fail OSM::APIChangesetActionInvalid.new(action_name)
      end
    end
  end

  def create_element
    with_model do |model, model_name, xml|
      element = model.new
      element.fill_using_xml!(xml)

      store_placeholder(xml['id'].to_i, element.id, model, model_name, xml)
    end
  end

  def modify_element
    with_model do |model, model_name, xml|
      fail OSM::APIBadXMLError.new(model_name, xml, 'ID is required when updating.') if xml['id'].nil?
      id = xml['id'].to_i
      # .to_i will return 0 if there is no number that can be parsed.
      # We want to make sure that there is no id with zero anyway
      # fail OSM::APIBadUserInput.new("ID of #{model_name} cannot be zero when updating.") if id == 0

      element = model.find(id)
      element.fill_using_xml!(xml)
    end
  end

  def delete_element
    with_model do |model, _, xml|
      id = xml['id'].to_i

      element = model.find(id)
      element.delete_from
    end
  end

  def store_placeholder(placeholder_id, new_id, model, model_name, xml)
    # when this element is saved it will get a new ID, so we save it
    # to produce the mapping which is sent to other elements.
    fail OSM::APIBadXMLError.new(model, xml) if placeholder_id.nil?

    # check if the placeholder ID has been given before and throw
    # an exception if it has - we can't create the same element twice.
    fail OSM::APIBadUserInput.new('Placeholder IDs must be unique for created elements.') if $ids[model_name.to_sym].include? placeholder_id

    # save placeholder => allocated ID map
    $ids[model_name.to_sym][placeholder_id] = new_id
  end
end
