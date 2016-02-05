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
# Data structure used for filling vector tile with data
# It reads from GeoSpatial Database and store it in xml format
# It also check if amount of elements does not exceed one tile limit.
class Tile
  MAX_ELEMENTS_AMOUNT = 10000
  SUPER_CONFIG_TAGS = %w(spacing conductor_N conductor_A conductor_B conductor_C).freeze

  def initialize(bbox)
    @bbox = bbox
    @doc = OSM::API.new.create_xml_doc

    @super_relations_id = []
    @relations_id = []
    @nodes_id = []

    add_ways_to_xml
    add_points_to_xml
    add_relations_to_xml
    add_super_relations_to_xml
  end

  def doc
    @doc.to_s
  end

  def add_ways_to_xml
    ways = PlanetOsmWay.where("ST_Intersects(way, #{@bbox.polygon_mercator})")
    check_amount(ways, 'ways')

    ways.each do |way|
      @nodes_id += way.nodes
      append_to_relation(@relations_id, way, 'configuration')

      @doc.root << way.to_xml_node
    end
  end

  def add_points_to_xml
    # TODO: verify if & is needed
    @nodes_id += PlanetOsmNode.where("ST_Intersects(geo_point, #{@bbox.polygon_mercator})").map(&:id)

    points = PlanetOsmNode.find(@nodes_id.uniq)
    check_amount(points, 'nodes')

    points.each do |point|
      @doc.root << point.to_xml_node
    end
  end

  def add_relations_to_xml
    relations = PlanetOsmRel.find(@relations_id.uniq)
    check_amount(relations, 'relations')

    relations.each do |relation|
      SUPER_CONFIG_TAGS.each do |tag_name|
        append_to_relation(@super_relations_id, relation, tag_name)
      end
      @doc.root << relation.to_xml_node
    end
  end

  def add_super_relations_to_xml
    super_relations = PlanetOsmRel.find(@super_relations_id.uniq)
    check_amount(super_relations, 'super_relations')

    super_relations.each do |super_relation|
      @doc.root << super_relation.to_xml_node
    end
  end

  def append_to_relation(array, element, tag_name)
    array.append(element.tags[tag_name]) unless element.tags[tag_name].nil?
  end

  def check_amount(elements, name)
    fail "To many #{name} in requested area" \
        if elements.count > MAX_ELEMENTS_AMOUNT
  end
end
