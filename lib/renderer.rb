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

class Renderer
  class << self
    undef_method :new

    def init
      @all_tiles = {}
    end

    def rerender(element)
      element.rerender if element.methods.include?(:rerender)
    end

    def add_point(lat, lon)
      (11..16).each do |zoom|
        n = 2**zoom
        lon_deg = Converter.lon_from_mercator(lon)
        lat_deg = Converter.lat_from_mercator(lat)
        lat_rad = Converter.to_rad(lat_deg)

        x_tile = n * ((lon_deg + 180) / 360.0)
        y_tile = n * (1 - (Math.log(Math.tan(lat_rad) + 1 / Math.cos(lat_rad)) / Math::PI)) / 2

        add_tile(x_tile, y_tile, zoom)
      end
    end

    def add_tile(x_tile, y_tile, zoom)
      @all_tiles[zoom] ||= {}
      @all_tiles[zoom][x_tile.to_i] ||= []
      @all_tiles[zoom][x_tile.to_i] << y_tile.to_i
    end

    def send_dirty
      logger = Logger.new(STDOUT)
      logger.level = Logger::INFO

      @all_tiles.each do |zoom, xy_tiles|
        xy_tiles.each do |x_tile, y_tiles|
          y_tiles.uniq.each do |y_tile|
            uri = URI("http://52.30.29.154/osm_tiles2/#{zoom}/#{x_tile}/#{y_tile}.png/dirty")

            logger.info("Send GET request to: #{uri}")
            response = Net::HTTP.get(uri)
            logger.info("Get response: #{response}")
          end
        end
      end
    end
  end
end
