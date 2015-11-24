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

module GeoRecord
  include GeoHelper
  require 'xml/libxml'

  CLIENT_SIDE_TAGS = %w(oneway type route)

  # from map request for vector tiles
  def to_xml_node
    el = XML::Node.new self.class::OSM_NAME
    el['id'] = id.to_s

    add_additional_nodes(el)

    add_tag_to_xml(el, 'name', self.name)
    add_tag_to_xml(el, 'power', self.power)
    # TODO: FEEDER_support - add_tag_to_xml(el, 'feeder id', self.feeder_id)

    add_other_tags_to_xml_node(el)

    el
  end

  def fill_using_xml!(pt)
    validate_element(pt)

    self.tags = read_tags_from_xml(pt)
    self.power = pop_tag('power')
    self.name = pop_tag('name')

    # TODO: NotYetImplemented   pop_tag('feeder_id')
    self.feeder_id = 1

    # TODO: should be done on client side - in ID
    CLIENT_SIDE_TAGS.each do |tag|
      pop_tag(tag)
    end

    fill_other_fields_using_xml(pt)

    save

    after_save if defined?(after_save) # TODO: do it better
  end

  def delete_from
    self.class.transaction do
      self.lock!

      self.delete if check_if_can_be_deleted?
    end
  end
end
