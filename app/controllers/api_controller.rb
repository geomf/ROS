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

class ApiController < ApplicationController
  require 'xml/libxml'

  SUPER_CONFIG_TAGS = %w(spacing conductor_N conductor_A conductor_B conductor_C)
  #
  # First the
  # bounding box (bbox) is checked to make sure that it is sane. All nodes
  # are searched, then all the ways that reference those nodes are found.
  # All Nodes that are referenced by those ways are fetched and added to the
  # list of nodes.
  # Then all the relations that reference the already found nodes and ways are
  # fetched. All the nodes and ways that are referenced by those ways are then
  # fetched. Finally all the xml is returned.
  def map
    # TODO: Check Bounding BOx size
    # TODO: Check amount of nodes - not here

    @bbox = BoundingBox.from_bbox_params(params)

    doc = OSM::API.new.create_xml_doc

    @relations_id = []
    @nodes_id = []

    add_ways_to_xml(doc)
    add_points_to_xml(doc)
    add_relations_to_xml(doc)
    add_super_relations_to_xml(doc)

    response.headers['Content-Disposition'] = "attachment; filename=\"map.osm\""

    render text: doc.to_s, content_type: 'text/xml'
  end

  def add_ways_to_xml(doc)
    ways = PlanetOsmWay.where("ST_Intersects(way, ST_Transform(ST_GeomFromText(#{@bbox.polygon}, 4326), 900913))")
    ways.each do |way|
      @nodes_id += way.nodes
      append_to_relation(@relations_id, way, 'configuration')

      doc.root << way.to_xml_node
    end
  end

  def add_points_to_xml(doc)
    # TODO: verify if & is needed
    @nodes_id += PlanetOsmNode.where("ST_Intersects(geo_point, ST_Transform(ST_GeomFromText(#{@bbox.polygon}, 4326), 900913))").map(&:id)

    points = PlanetOsmNode.find(@nodes_id.uniq)
    points.each do |point|
      doc.root << point.to_xml_node
    end
  end

  def add_relations_to_xml(doc)
    @super_relations_id = []

    relations = PlanetOsmRel.find(@relations_id.uniq)
    relations.each do |relation|
      SUPER_CONFIG_TAGS.each do |tag_name|
        append_to_relation(@super_relations_id, relation, tag_name)
      end
      doc.root << relation.to_xml_node
    end
  end

  def add_super_relations_to_xml(doc)
    super_relations = PlanetOsmRel.find(@super_relations_id.uniq)
    super_relations.each do |super_relation|
      doc.root << super_relation.to_xml_node
    end
  end

  def append_to_relation(array, element, tag_name)
    array.append(element.tags[tag_name]) unless element.tags[tag_name].nil?
  end

  # do we need this method? maybe use it to send API version
  def capabilities
    doc = OSM::API.new.create_xml_doc

    render text: doc.to_s, content_type: 'text/xml'
  end

  def list
    type_name = params['type_name']
    model = params['model']

    fail OSM::APIBadUserInput.new("The parameter #{type_name} is required, and must be of the form #{type_name}=id[,id[,id...]]") unless params[type_name]

    ids = params[type_name].split(',').collect(&:to_i)

    response = prepare_response(ids, model)

    render text: response, content_type: 'text/xml'
  end

  def prepare_response(ids, model)
    doc = OSM::API.new.create_xml_doc

    model.find(ids).each do |element|
      doc.root << element.to_xml_node
    end

    doc.to_s
  end

  def upload
    diff_reader = DiffReader.new(request.raw_post)
    diff_reader.commit

    render text: ''
  end
end
