module RelationHelper
  def gather_all_relations
    relations_ids = {}
    GeoHelper::RELATION_TAGS.each do |rel_role|
      model = (rel_role == 'configuration') ? PlanetOsmWay : PlanetOsmRel
      relations_ids[rel_role] = model.where('tags @> hstore(:key, :value)', key: rel_role, value: id.to_s).pluck(:id)
    end
    relations_ids
  end

  def add_members_to_xml(el, all_members)
    all_members.each do |role, members|
      member_type = (role == 'configuration') ? 'way' : 'relation'

      members.each do |member|
        member_el = XML::Node.new 'member'
        member_el['type'] = member_type
        member_el['role'] = role
        member_el['ref'] = member.to_s
        el << member_el
      end
    end
  end

  def subtract(old_members, new_members)
    members = old_members.clone
    old_members.each do |rel_role, _|
      members[rel_role] -= new_members[rel_role] if new_members.has_key?(rel_role)
    end
    members
  end
end
