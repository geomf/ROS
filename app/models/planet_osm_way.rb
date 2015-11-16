class PlanetOsmWay < ActiveRecord::Base
  include GeoRecord
  include WayHelper

  def osm_name; 'way' end


  def add_additional_nodes(el)
    self.nodes.each do |nd_id|
      node_el = XML::Node.new "nd"
      node_el["ref"] = nd_id.to_s
      el << node_el
    end


    add_tag_to_xml(el, 'oneway', 'yes')
=begin
    unless self.tags["configuration"].nil?
      add_tag_to_xml(el, 'ref', self.tags["configuration"])
    end
=end

    #do not send self.way in XML
  end


  def create_additional_nodes_from_xml(pt)
    self.nodes = []

    pt.find("nd").each do |nd|
      id = nd["ref"].to_i
      self.nodes << id
    end

    # some elements may have placeholders for other elements, so we must fix these before saving the element.
    fix_placeholders!

    self.way = create_way_as_geo_element(nodes)
  end




  def check_if_can_be_deleted?
    true
  end


  def validate_element(pt)

    nodes = pt.find("nd")
    return false if nodes.empty?

    #TODO: Verify if only 2 should be avaliable
    if nodes.length < 2
      fail OSM::APITooManyWayNodesError.new(id, nodes.length, 2)
    end

=begin
   #TODO: check if nodes_id are already in db
    finded_nodes = PlanetOsmNode.find(nodes)
    db_nds = PlanetOsmNode.where(:id => new_nds).lock("for share")

    if db_nds.length < new_nds.length
      missing = new_nds - db_nds.collect(&:id)
      fail OSM::APIPreconditionFailedError.new("Way #{id} requires the nodes with id in (#{missing.join(',')}), which do not exist.")
    end
=end
    true
  end



  ##
  # if any referenced nodes are placeholder IDs (i.e: are negative) then
  # this calling this method will fix them using the map from placeholders
  # to IDs +id_map+.
  def fix_placeholders!()
    nodes.map! do |node_id|
      if node_id < 0
        new_id = $ids[:node][node_id]
        fail OSM::APIBadUserInput.new("Placeholder node not found for reference #{node_id} in way #{id.nil? ? placeholder_id : id}") if new_id.nil?
        new_id
      else
        node_id
      end
    end
  end

end
