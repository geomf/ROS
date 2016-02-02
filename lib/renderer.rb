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
  def self.current
    RequestStore[:rerender]
  end

  def initialize
    @all_tiles = {}
  end

  def rerender(element)
    element.rerender if element.methods.include?(:rerender)
  end

  def add_point(lat, lon, feeder_id)
    user_id = Feeder.find(feeder_id)

    (11..16).each do |zoom|
      n = 2**zoom
      lon_deg = Converter.lon_from_mercator(lon)
      lat_deg = Converter.lat_from_mercator(lat)
      lat_rad = Converter.to_rad(lat_deg)

      x_tile = n * ((lon_deg + 180) / 360.0)
      y_tile = n * (1 - (Math.log(Math.tan(lat_rad) + 1 / Math.cos(lat_rad)) / Math::PI)) / 2

      add_tile(x_tile, y_tile, zoom, user_id)
    end
  end

  def add_tile(x_tile, y_tile, zoom, user)
    @all_tiles[zoom] ||= {}
    @all_tiles[zoom][x_tile] ||= {}
    @all_tiles[zoom][x_tile][y_tile] ||= [0] # add super_admin tile
    @all_tiles[zoom][x_tile][y_tile] << user
  end

  def send_dirty
    logger = Logger.new(STDOUT)
    logger.level = Logger::INFO

    foreground_host = JSON.parse(ENV['VCAP_SERVICES'])['user-provided'][0]['credentials']['mod-tile-fg-host']

    @all_tiles.each do |zoom, xy_tiles|
      xy_tiles.each do |x_tile, y_tiles|
        y_tiles.each do |y_tile, users|
          users.uniq.each do |user_id|
            uri = URI("#{foreground_host}/osm_tiles2/#{user_id}/#{zoom}/#{x_tile}/#{y_tile}.png/dirty")

            logger.info("Send GET request to: #{uri}")
            response = Net::HTTP.get(uri)
            logger.info("Get response: #{response}")
          end
        end
      end
    end
  end
end
