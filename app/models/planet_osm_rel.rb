#
# Rails OMF Server (ROS) Software for visualizing power systems behavior
# Copyright (c) 2015, Intel Corporation.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms and conditions of the GNU General Public License,
# version 2, as published by the Free Software Foundation.
#
# This program is distributed in the hope it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#

##
# class representation for elements from planet_osm_rel table in DB
# it has functionality to save information from db as xml
# and also creating new elements in db using xml with some validation
class PlanetOsmRel < ActiveRecord::Base
  include GeoRecord
  include RelationHelper

  OSM_NAME = 'relation'.freeze

  def add_additional_nodes(el)
    relations = power.end_with?('_configuration') ? gather_normal_relations : gather_super_relations
    add_members_to_xml(el, relations)

    add_tag_to_xml(el, 'route', 'power')
    add_tag_to_xml(el, 'type', 'route')
  end

  def fill_other_fields_using_xml(pt)
    @new_members = {}
    pt.find('member').each do |member|
      @new_members[member['role']] ||= []

      proper_id = Placeholder.current.get_fixed_id(member['ref'].to_i, member['type'])
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

        action.call(element, rel_role, id)
        element.save
      end
    end
  end

  def check_if_can_be_deleted?
    # TODO: find all members and delete referation to this element and always return true after deletion
    true
  end

  # it is empty by design
  def validate_element(_)
  end
end
