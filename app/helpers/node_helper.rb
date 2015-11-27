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

module NodeHelper
  def create_point_as_geo_element(lat, lon)
    factory = RGeo::Cartesian.factory(srid: 900913)

    factory.point(lon / 100.0, lat / 100.0)
  end

  def in_world?
    # return false if lat < -90 || lat > 90
    # return false if lon < -180 || lon > 180
    true
  end
end
