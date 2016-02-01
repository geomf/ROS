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

  CLIENT_SIDE_TAGS = %w(oneway type route).freeze

  class << self
    def create(placeholder_id, model, xml)
      element = model.new
      element.fill!(xml)

      Placeholder.store(placeholder_id, element.id, model, xml)

      Renderer.rerender(element)
    end

    def modify(id, model, xml)
      element = model.find(id)

      Renderer.rerender(element) # remove_old_tile

      element.fill!(xml)

      Renderer.rerender(element)
    end

    def delete(id, model, _)
      element = model.find(id)

      element.delete if element.check_if_can_be_deleted?

      Renderer.rerender(element)
    end
  end

  # from map request for vector tiles
  def to_xml_node
    el = XML::Node.new self.class::OSM_NAME
    el['id'] = id.to_s

    add_additional_nodes(el)

    add_tag_to_xml(el, 'name', self.name)
    add_tag_to_xml(el, 'power', self.power)
    add_tag_to_xml(el, 'feeder_id', self.feeder_id.to_s)

    add_other_tags_to_xml_node(el)

    el
  end

  def fill!(pt)
    validate_element(pt)

    self.tags = read_tags_from_xml(pt)
    self.power = pop_tag('power', 'node')
    self.name = pop_tag('name', 'test_name')

    self.feeder_id = pop_tag('feeder_id', 1)
    DiffReader.changed_feeders[self.feeder_id.to_i] = true

    # TODO: should be done on client side - in ID
    CLIENT_SIDE_TAGS.each do |tag|
      pop_tag(tag)
    end

    fill_other_fields_using_xml(pt)

    save

    after_save if defined?(after_save) # TODO: do it better
  end
end
