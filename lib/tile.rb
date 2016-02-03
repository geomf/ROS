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

class Tile
  SUPER_CONFIG_TAGS = %w(spacing conductor_N conductor_A conductor_B conductor_C).freeze

  def initialize(params)
    # TODO: Check amount of nodes - not here

    @bbox = BoundingBox.from_bbox_params(params)
    @doc = OSM::API.new.create_xml_doc

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
    points.each do |point|
      @doc.root << point.to_xml_node
    end
  end

  def add_relations_to_xml
    @super_relations_id = []

    relations = PlanetOsmRel.find(@relations_id.uniq)
    relations.each do |relation|
      SUPER_CONFIG_TAGS.each do |tag_name|
        append_to_relation(@super_relations_id, relation, tag_name)
      end
      @doc.root << relation.to_xml_node
    end
  end

  def add_super_relations_to_xml
    super_relations = PlanetOsmRel.find(@super_relations_id.uniq)
    super_relations.each do |super_relation|
      @doc.root << super_relation.to_xml_node
    end
  end

  def append_to_relation(array, element, tag_name)
    array.append(element.tags[tag_name]) unless element.tags[tag_name].nil?
  end
end
