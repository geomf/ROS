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
# class representation for elements from planet_osm_nodes table in DB
# it has functionality to save information from db as xml
# and also creating new elements in db using xml with some validation
class PlanetOsmNode < ActiveRecord::Base
  include GeoRecord
  include NodeHelper

  OSM_NAME = 'node'.freeze

  def add_additional_nodes(el)
    el['lat'] = Converter.lat_from_mercator(lat).to_s
    el['lon'] = Converter.lon_from_mercator(lon).to_s
  end

  def fill_other_fields_using_xml(pt)
    self.lon = Converter.lon_to_mercator(pt['lon'])
    self.lat = Converter.lat_to_mercator(pt['lat'])
    self.geo_point = create_point_as_geo_element(lat, lon)
  end

  def after_save
    PlanetOsmWay.where("#{id} = ANY(nodes)").find_each do |way|
      way.way = way.create_way_as_geo_element(way.nodes)
      way.save
      Renderer.current.rerender(way)
    end
  end

  def check_if_can_be_deleted?
    # TODO: Verify if node is used by any way
    # ways = Way.joins(:way_nodes).where(:current_way_nodes => { :node_id => id }).order(:id)
    # fail OSM::APIPreconditionFailedError,
    #      "Node #{id} is still used by ways #{ways.collect(&:id).join(',')}." unless ways.empty?
    true
  end

  def validate_element(pt)
    fail OSM::APIBadXMLError.new('node', pt, 'lat missing') if pt['lat'].nil?
    fail OSM::APIBadXMLError.new('node', pt, 'lon missing') if pt['lon'].nil?
    fail OSM::APIBadUserInput, 'The node is outside this world' unless self.in_world?(pt['lat'], pt['lon'])
  end

  def rerender
    Renderer.current.add_point(lat, lon, feeder_id)
  end
end
