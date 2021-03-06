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

class AddIndices < ActiveRecord::Migration
  def change
    add_index :planet_osm_ways, :tags, using: :gin
    add_index :planet_osm_rels, :tags, using: :gin

    add_index :planet_osm_nodes, :feeder_id
    add_index :planet_osm_ways, :feeder_id
    add_index :planet_osm_rels, :feeder_id
  end
end
