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

module WayHelper
  def create_way_as_geo_element(nodes)
    factory = RGeo::Cartesian.factory(srid: 900913)
    points = []

    nodes.each do |nd_id|
      node = PlanetOsmNode.find(nd_id)
      points << factory.point(node.lon / 100.0, node.lat / 100.0)
    end

    factory.line_string(points)
  end
end
