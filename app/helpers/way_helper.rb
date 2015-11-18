module WayHelper
  def create_way_as_geo_element(nodes)
    factory = RGeo::Cartesian.factory(srid: 900913)
    points = []

    nodes.each do |nd_id|
      node = PlanetOsmNode.find(nd_id)
      points << factory.point(node.lon/100.0, node.lat/100.0)
    end

    return factory.line_string(points)
  end
end