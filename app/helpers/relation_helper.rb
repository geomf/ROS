module RelationHelper
  def gather_all_relations
    gather_normal_relations + gather_super_relations
  end

  def gather_super_relations
    relations_ids = {}
    GeoHelper::SUPER_RELATION_TAGS.each do |rel_role|
      relations_ids[rel_role] = PlanetOsmRel.where('tags @> hstore(:key, :value)', key: rel_role, value: id.to_s).pluck(:id)
    end
    relations_ids
  end

  def gather_normal_relations
    relations_ids = {}
    relations_ids['configuration'] = PlanetOsmWay.where('tags @> hstore(:key, :value)', key: 'configuration', value: id.to_s).pluck(:id)
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
      members[rel_role] -= new_members[rel_role] if new_members.key?(rel_role)
    end
    members
  end
end
