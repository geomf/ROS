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
# This is main controller for this server
# Main API endpoints are:
#  - map - for vector tiles
#  - upload - for uploading edits
# Other are:
# - list (node,way.relations) - for getting information about specified elements by id
# - rerender - for sending request to mod_tile for rerendering whole feeder
# - feeders - for getting basic data about feeders which are owned by specified user
# - capabilities - DEPRECATED - currently not used for anything. Is required by ID editor
class ApiController < ApplicationController
  require 'xml/libxml'

  #
  # First the bounding box (bbox) is checked to make sure that it is sane.
  # All ways are searched.
  # All Nodes that are referenced by those ways are fetched and added to the list of nodes found by bounding box
  # Then all the relations that reference the already found nodes and ways are fetched.
  # Some nodes and ways which are describe by relations ar not been fetched!
  # Finally all the xml is returned.
  def map
    tile = Tile.new(BoundingBox.from_bbox_params(params))

    response.headers['Content-Disposition'] = 'attachment; filename="map.osm"'

    render text: tile.doc, content_type: 'text/xml'
  end

  def capabilities
    doc = OSM::API.new.create_xml_doc

    render text: doc.to_s, content_type: 'text/xml'
  end

  def list
    type_name = params['type_name']
    model = params['model']

    fail OSM::APIBadUserInput,
         "The parameter #{type_name} is required, and must be of the form #{type_name}=id[,id[,id...]]" \
      unless params[type_name]

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
    RequestStore.store[:placeholder] = Placeholder.new
    RequestStore.store[:rerender] = Renderer.new
    RequestStore.store[:diff_reader] = DiffReader.new(request.raw_post)

    DiffReader.current.commit

    render text: prepare_feeders_response
  end

  def prepare_feeders_response
    doc = OSM::API.new.create_xml_doc

    DiffReader.current.feeders_changed.each do |feeder_id, _|
      el = XML::Node.new 'feeder'
      el['id'] = feeder_id.to_s

      doc.root << el
    end

    doc.to_s
  end

  def rerender
    feeder_id = params['feeder_id']
    RequestStore.store[:rerender] = Renderer.new

    PlanetOsmNode.find_by_feeder_id(feeder_id).each(&:rerender)
    PlanetOsmWay.find_by_feeder_id(feeder_id).each(&:rerender)

    Renderer.current.send_dirty
    render text: ''
  end

  def feeders
    user_id = params['user_id']
    feeders = if is_admin?(user_id)
                Feeder.all
              else
                Feeder.find_by_user_id(user_id)
              end

    doc = OSM::API.new.create_xml_doc

    feeders.each do |feeder|
      doc.root << feeder.to_xml_node
    end

    render text: doc.to_s, content_type: 'text/xml'
  end

  def admin?(user_id)
    user_id.to_i == 0
  end
end
