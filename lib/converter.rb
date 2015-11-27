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

class Converter
  SM_A = 6378137.0

  def self.lon_to_mercator(old_lon)
    lon_rad = to_rad(old_lon.to_f)

    SM_A * lon_rad * 100
  end

  def self.lat_to_mercator(old_lat)
    lat_rad = to_rad(old_lat.to_f)

    SM_A * Math.log((Math.sin(lat_rad) + 1) / Math.cos(lat_rad)) * 100
  end

  def self.lon_from_mercator(old_lon)
    lon_rad = old_lon.to_f / 100 / SM_A

    to_deg(lon_rad)
  end

  def self.lat_from_mercator(old_lat)
    lat_rad = Math.atan(Math.exp(old_lat.to_f / 100 / SM_A))

    to_deg(lat_rad) * 2 - 90
  end

  def self.to_rad(deg)
    deg / 180.0 * Math::PI
  end

  def self.to_deg(rad)
    rad * 180.0 / Math::PI
  end
end
