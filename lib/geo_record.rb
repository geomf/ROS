module GeoRecord
#  self.abstract_class = true
  require "xml/libxml"

  UNSHOWN_TAGS = %w(configuration spacing conductor_N conductor_A conductor_B conductor_C)

  # from map request for vector tiles
  def to_xml_node
    el = XML::Node.new self.osm_name
    el["id"] = id.to_s

    add_additional_nodes(el)
    add_tags_to_xml_node(el)

    el
  end


  # Read in xml as text and return it's  object representation
  def fill_using_xml!(pt)
    validate_basics(pt)
    validate_element(pt)

    # TODO: NotYetImplemented
    self.name = "new_element"
    self.feeder_id = 1

    self.power = ""

    self.tags = {}

    # Add in any tags from the XML
    pt.find('tag').each do |tag|
      validate_tag(pt,tag)

      self.tags[tag['k']] = tag['v'] unless tag['k'] == "power"
      self.power = tag['v'] if tag['k'] == "power"
    end



    create_additional_nodes_from_xml(pt)

    save
  end


  def delete_from
    self.class.transaction do
      self.lock!

      self.delete if check_if_can_be_deleted?
    end
  end







  def add_tag_to_xml(el, key, value)
    tag_el = XML::Node.new 'tag'
    tag_el['k'] = key
    tag_el['v'] = value
    el << tag_el
  end

  def add_tags_to_xml_node(el)
    add_tag_to_xml(el, "name", self.name)
    add_tag_to_xml(el, "power", self.power)
    self.tags.each do |key, value|
      add_tag_to_xml(el, "power:" + key, value) unless UNSHOWN_TAGS.include?(key) unless value.nil?
    end
  end



  def validate_basics(pt)
    # if name is
    # if feeder ID
    # if power type in tags ?
    # fail OSM::APIPreconditionFailedError.new("Cannot create #{model_name}: data is invalid.")
  end


  def validate_tag(pt,tag)
    fail OSM::APIBadXMLError.new(self.class, pt, 'tag is missing key') if tag['k'].nil?
    fail OSM::APIBadXMLError.new(self.class, pt, 'tag is missing value') if tag['v'].nil?
    fail OSM::APIDuplicateTagsError.new("geoElement", id, tag['k']) if tags.include? tag['k']
  end


end
