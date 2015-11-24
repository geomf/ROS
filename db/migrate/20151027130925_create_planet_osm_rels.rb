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

class CreatePlanetOsmRels < ActiveRecord::Migration
  def change
    create_table :planet_osm_rels do |t|
      t.text :name
      t.text :power, null: false
      t.hstore :tags

      t.belongs_to :feeder
    end
  end
end
