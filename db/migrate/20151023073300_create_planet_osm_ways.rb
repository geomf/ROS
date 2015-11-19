class CreatePlanetOsmWays < ActiveRecord::Migration
  def change
    create_table :planet_osm_ways do |t|
      t.text :name
      t.text :power, null: false
      t.hstore :tags

      t.bigint :nodes, array: true
      t.line_string :way, srid:900913
      t.belongs_to :feeder
    end
  end
end
