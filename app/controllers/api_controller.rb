class ApiController < ApplicationController
  require 'xml/libxml'

  SUPER_CONFIG_TAGS = %w(spacing conductor_N conductor_A conductor_B conductor_C)
  #
  # First the
  # bounding box (bbox) is checked to make sure that it is sane. All nodes
  # are searched, then all the ways that reference those nodes are found.
  # All Nodes that are referenced by those ways are fetched and added to the list
  # of nodes.
  # Then all the relations that reference the already found nodes and ways are
  # fetched. All the nodes and ways that are referenced by those ways are then
  # fetched. Finally all the xml is returned.
  def map
    # TODO: Check Bounding BOx size
    # TODO: Check amount of nodes - not here

    bbox = BoundingBox.from_bbox_params(params)

    doc = OSM::API.new.get_xml_doc

    nodes_id = []
    relations_id = []


    ways = PlanetOsmWay.where("ST_Intersects(way, ST_Transform(ST_GeomFromText(#{bbox.get_polygon}, 4326), 900913))")

    ways.each do |way|
      nodes_id += way.nodes
      append_to_relation(relations_id, way, "configuration")

      doc.root << way.to_xml_node
    end


    nodes_id.uniq.each do |node_id|
      point = PlanetOsmNode.find(node_id)
      doc.root << point.to_xml_node
    end


    all_relations_id = []
    relations_id.uniq.each do |relation_id|
      all_relations_id.append(relation_id)

      relation = PlanetOsmRel.find(relation_id)


      SUPER_CONFIG_TAGS.each do |tag_name|
        append_to_relation(all_relations_id, relation, tag_name)
      end
    end

    all_relations_id.uniq.each do |relation_id|
      relation = PlanetOsmRel.find(relation_id)

      doc.root << relation.to_xml_node
    end


    response.headers['Content-Disposition'] = "attachment; filename=\"map.osm\""

    render :text => doc.to_s, :content_type => 'text/xml'
  end


  def append_to_relation(array,element, tag_name)
    array.append(element.tags[tag_name]) unless element.tags[tag_name].nil?
  end


  # External apps that use the api are able to query the api to find out some
  # parameters of the API. It currently returns:
  # * minimum and maximum API versions that can be used.
  # * maximum area that can be requested in a bbox request in square degrees
  # * number of tracepoints that are returned in each tracepoints page
  def capabilities
    doc = OSM::API.new.get_xml_doc
=begin
    api = XML::Node.new "api"
    version = XML::Node.new "version"
    version["minimum"] = "0.6"    # "#{API_VERSION}"
    version["maximum"] = "0.6"    # "#{API_VERSION}"
    api << version
    area = XML::Node.new "area"
    area["maximum"] = "0.2"   #MAX_REQUEST_AREA.to_s
    api << area
    tracepoints = XML::Node.new "tracepoints"
    tracepoints["per_page"] = "5000"  #TRACEPOINTS_PER_PAGE.to_s
    api << tracepoints
    waynodes = XML::Node.new "waynodes"
    waynodes["maximum"] = "2000"   #MAX_NUMBER_OF_WAY_NODES.to_s
    api << waynodes
    timeout = XML::Node.new "timeout"
    timeout["seconds"] = "300"    #API_TIMEOUT.to_s
    api << timeout
    status = XML::Node.new "status"
    status["database"] =  "online"   #database_status.to_s
    status["api"] = "online"   #api_status.to_s
    status["gpx"] = "online"   #gpx_status.to_s
    api << status
    doc.root << api
=end
    render :text => doc.to_s, :content_type => 'text/xml'
  end



  def list
    type_name = params["type_name"]
    model = params["model"]

    unless params[type_name]
      fail OSM::APIBadUserInput.new("The parameter #{type_name} is required, and must be of the form #{type_name}=id[,id[,id...]]")
    end

    ids = params[type_name].split(',').collect(&:to_i)

    if ids.length == 0
      fail OSM::APIBadUserInput.new("No #{type_name} were given to search for")
    end

    doc = OSM::API.new.get_xml_doc

    model.find(ids).each do |element|
      doc.root << element.to_xml_node
    end

    render :text => doc.to_s, :content_type => "text/xml"
  end




  def upload
    diff_reader = DiffReader.new(request.raw_post)
    diff_reader.commit

    render :text => ''
  end
end

