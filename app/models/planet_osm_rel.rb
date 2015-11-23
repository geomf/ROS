class PlanetOsmRel < ActiveRecord::Base
  include GeoRecord
  include RelationHelper
  def osm_name; 'relation' end

  def add_additional_nodes(el)
    relations = (self.power.end_with?('_configuration')) ? gather_normal_relations : gather_super_relations
    add_members_to_xml(el, relations)

    add_tag_to_xml(el, 'route', 'power')
    add_tag_to_xml(el, 'type', 'route')
  end

  def fill_other_fields_using_xml(pt)
    @new_members = {}
    pt.find('member').each do |member|
      @new_members[member['role']] ||= []

      proper_id = get_fixed_placeholder_id(member['ref'].to_i, member['type'])
      @new_members[member['role']].append(proper_id)
    end
  end

  def after_save
    old_members = gather_all_relations

    to_add_or_change = @new_members
    to_delete = subtract(old_members, @new_members)

    modify_rel = proc { |element, member_role, member_id| element.tags[member_role] = member_id }
    update(to_add_or_change, modify_rel)

    delete_rel = proc { |element, member_role, _| element.tags.delete(member_role) }
    update(to_delete, delete_rel)
  end

  def update(members, action)
    members.each do |rel_role, relations|
      model = (rel_role == 'configuration') ? PlanetOsmWay : PlanetOsmRel

      relations.each do |member_id|
        element = model.find(member_id)

        action.call(element, rel_role, self.id)
        element.save
      end

      # fail OSM::APIBadXMLError.new('relation', member, "The #{member['type']} is not allowed only") unless TYPES.include? member['type']
    end
  end

  def check_if_can_be_deleted?
    # TODO: find all members and delete referation to this element.
    # rel = joins(:relation).find_by("member_type = 'Relation' AND member_id = ? ", id)
    # fail OSM::APIPreconditionFailedError.new("The relation #{new_relation.id} is used by other elements.") unless rel.nil?
  end

  def validate_element(_)
    # fail OSM::APIPreconditionFailedError.new("Cannot update relation #{id}: data or member data is invalid.")
  end
end
