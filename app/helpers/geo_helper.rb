module GeoHelper
  SUPER_RELATION_TAGS = %w(spacing conductor_N conductor_A conductor_B conductor_C)
  RELATION_TAGS = %w(configuration spacing conductor_N conductor_A conductor_B conductor_C)

  def add_other_tags_to_xml_node(el)
    self.tags.each do |key, value|
      add_tag_to_xml(el, 'power:' + key, value) unless RELATION_TAGS.include?(key) unless value.nil?
    end
  end

  def add_tag_to_xml(el, key, value)
    tag_el = XML::Node.new 'tag'
    tag_el['k'] = key
    tag_el['v'] = value
    el << tag_el
  end

  def read_tags_from_xml(pt)
    tags = {}
    pt.find('tag').each do |tag|
      validate_tag(pt, tag)
      tag['k'].slice!('power:')
      tags[tag['k']] = tag['v']
    end
    tags
  end

  def pop_tag(name)
    # TODO: check if tag exists
    # fail OSM::APIPreconditionFailedError.new("Cannot create #{model_name}: data is invalid.")

    value = self.tags[name]
    self.tags.delete(name)
    value
  end

  def validate_tag(pt, tag)
    fail OSM::APIBadXMLError.new(self.class, pt, 'tag is missing key') if tag['k'].nil?
    fail OSM::APIBadXMLError.new(self.class, pt, 'tag is missing value') if tag['v'].nil?
    fail OSM::APIDuplicateTagsError.new('geoElement', id, tag['k']) if tags.include? tag['k']
  end

  ##
  # if any referenced nodes are placeholder IDs (i.e: are negative) then
  # this calling this method will fix them using the map from placeholders
  # to IDs +id_map+.
  def get_fixed_placeholder_id(old_id, type)
    if old_id < 0
      new_id = $ids[type][old_id]
      # fail OSM::APIBadUserInput.new("Placeholder #{type} not found for reference #{old_id} in #{self.class} #{self.id.nil? ? placeholder_id : self.id}") if new_id.nil?
      new_id
    else
      old_id
    end
  end
end
