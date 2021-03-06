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
# class representation for elements from feeders table in DB
# it has functionality to save information from db as xml
class Feeder < ActiveRecord::Base
  def to_xml_node
    el = XML::Node.new 'feeder'
    el['id'] = id.to_s
    el['name'] = name
    el['lat'] = Converter.lat_from_mercator(lat).to_s
    el['lon'] = Converter.lon_from_mercator(lon).to_s

    el
  end
end
