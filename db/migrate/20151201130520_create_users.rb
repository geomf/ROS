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

class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string   "username", null: false
      t.string   "reg_key",         limit: 80
      t.datetime "timestamp"
      t.boolean  "registered"
      t.string   "csrf",            limit: 80
      t.string   "password_digest", limit: 200
    end

    reversible do |change|
      change.up do
        execute <<-SQL
          CREATE TYPE role AS ENUM ('admin', 'user', 'public');
        SQL

        add_column :users, "role", :role
      end

      change.down do
        remove_column :users, "role"
        execute <<-SQL
          DROP TYPE role;
        SQL
      end
    end
  end
end
