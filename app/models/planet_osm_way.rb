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
# class representation for elements from planet_osm_ways table in DB
# it has functionality to save information from db as xml
# and also creating new elements in db using xml with some validation
class PlanetOsmWay < ActiveRecord::Base
  include GeoRecord
  include WayHelper

  OSM_NAME = 'way'.freeze

  def add_additional_nodes(el)
    nodes.each do |nd_id|
      node_el = XML::Node.new 'nd'
      node_el['ref'] = nd_id.to_s
      el << node_el
    end

    add_tag_to_xml(el, 'oneway', 'yes')
  end

  def fill_other_fields_using_xml(pt)
    self.nodes = []

    pt.find('nd').each do |nd|
      proper_id = Placeholder.current.get_fixed_id(nd['ref'].to_i, :node)
      nodes << proper_id
    end

    self.way = create_way_as_geo_element(nodes)
  end

  def check_if_can_be_deleted?
    true
  end

  def validate_element(pt)
    nodes = pt.find('nd')
    return false if nodes.empty?

    fail OSM::APIBadUserInput, 'Only lines with two nodes are allowed' if nodes.length != 2

    # TODO: check if nodes_id are already in db
    # finded_nodes = PlanetOsmNode.find(nodes)
    # db_nds = PlanetOsmNode.where(:id => new_nds).lock("for share")

    # if found_nodes.length < nodes.length
    #  missing = new_nds - db_nds.collect(&:id)
    #  fail OSM::APIPreconditionFailedError,
    #    "Way #{id} requires the nodes with id in (#{missing.join(',')}), which do not exist."
    # end
  end

  def rerender
    # TODO: rerender whole edge not only Start and End point
    nodes.each do |node_id|
      node = PlanetOsmNode.find(node_id)
      Renderer.current.add_point(node.lat, node.lon, node.feeder_id)
    end
  end
end
