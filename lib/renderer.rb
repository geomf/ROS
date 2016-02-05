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
# Data structure used for rerender foreground tiles in mod_tile after each edition
# Mod_tile address is specified in environment variables under VCAP_SERVICES
# Minimum and maximum zoom for re-rendering purpose are specified as Constants
class Renderer
  MIN_ZOOM = 11
  MAX_ZOOM = 16

  def self.current
    RequestStore[:rerender]
  end

  def initialize
    @all_tiles = {}

    @foreground_host = JSON.parse(ENV['VCAP_SERVICES'])['user-provided'][0]['credentials']['mod-tile-fg-host']

    @logger = Logger.new(STDOUT)
    @logger.level = Logger::INFO
  end

  def rerender(element)
    element.rerender if element.methods.include?(:rerender)
  end

  def add_point(lat, lon, feeder_id)
    user_id = Feeder.find(feeder_id).user_id

    (MIN_ZOOM..MAX_ZOOM).each do |zoom|
      x_tile = Converter.tile_x_from_lon(lon, zoom)
      y_tile = Converter.tile_y_from_lat(lat, zoom)

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
    @all_tiles.each do |zoom, xy_tiles|
      xy_tiles.each do |x_tile, y_tiles|
        y_tiles.each do |y_tile, users|
          users.uniq.each do |user_id|
            uri = URI("#{@foreground_host}/osm_tiles2/#{user_id}/#{zoom}/#{x_tile}/#{y_tile}.png/dirty")

            @logger.info("Send GET request to: #{uri}")
            response = Net::HTTP.get(uri)
            @logger.info("Get response: #{response}")
          end
        end
      end
    end
  end
end
