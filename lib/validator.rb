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
# Static class used for converting geo formats.
# From LatLon to Google Mercator and vice versa
# Additionally it also converts geo location to tile number.
class Validator
  class << self
    undef_method :new

    def read_int(value, name)
      Integer(value)
    rescue
      raise OSM::APIBadUserInput, "Cannot parse #{name} as int which is #{value}"
    end

    def read_float(value, name)
      Float(value)
    rescue
      raise OSM::APIBadBoundingBox, "Cannot parse #{name} as float which is #{value}"
    end
  end
end
