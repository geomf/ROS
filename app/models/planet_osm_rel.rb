class PlanetOsmRel < ActiveRecord::Base
  include GeoRecord
  include RelationHelper
  def osm_name; 'relation' end


  def add_additional_nodes(el)
    members_edge = PlanetOsmWay.where("tags @> hstore(:key, :value)", key: "configuration", value: id.to_s).pluck(:id)
    add_members_to_xml(el, members_edge, "way")

    members_rel = PlanetOsmRel.where("tags @> hstore(:key, :value)", key: "spacing", value: id.to_s).pluck(:id)
    add_members_to_xml(el, members_rel, "relation")


    add_tag_to_xml(el, 'name', name)
    add_tag_to_xml(el, 'route', 'power')
    add_tag_to_xml(el, 'type', 'route')
  end


  def create_additional_nodes_from_xml(pt)
    @members = pt.find("member")

    # some elements may have placeholders for other elements, so we must fix these before saving the element.
    fix_placeholders!

  end




  def save_members

    members = self.members.clone

#    todelete = old_memebers - members
#    toadd = members - old_memebers

    @members.each do |member|
      element = PlanetOsmRel.find(id: member["ref"].to_i) if member["type"] == 'relation'
      element = PlanetOsmWay.find(id: member["ref"].to_i) if member["type"] == 'way'

      #RelationMember.create(type: member["type"], elemnt_id: member["ref"].to_i, rel_id: self.id)

      fail OSM::APIBadXMLError.new("relation", pt, "The #{member['type']} is not allowed only") unless TYPES.include? member["type"]
    end
  end


  def check_if_can_be_deleted?

    # TODO: find all memebers and delete referation to this element.
    rel = joins(:relation).find_by("member_type = 'Relation' AND member_id = ? ", id)
    fail OSM::APIPreconditionFailedError.new("The relation #{new_relation.id} is used by other elements.") unless rel.nil?
  end



  ##
  # if any members are referenced by placeholder IDs (i.e: negative) then
  # this calling this method will  fix them using the map from placeholders
  # to IDs +id_map+.
  def fix_placeholders!
    self.nodes.each do |node|
    #nodes.map! do |type, id, role|
      old_id = node["id"]
      if old_id < 0
        new_id = $ids[node["type"]][old_id]
        fail OSM::APIBadUserInput.new("Placeholder #{node["type"]} not found for reference #{old_id} in relation #{self.id.nil? ? placeholder_id : self.id}.") if new_id.nil?
        node["id"] = new_id
      end
    end
  end


  def validate_element(pt)
    fail OSM::APIPreconditionFailedError.new("Cannot update relation #{id}: data or member data is invalid.")
  end

end
