class CreatePlanetOsmNodes < ActiveRecord::Migration
  def change
    create_table :planet_osm_nodes do |t|
      t.text :name
      t.text :power, null: false
      t.hstore :tags

      t.integer :lat
      t.integer :lon
      t.st_point :geo_point, srid: 900913
      t.belongs_to :feeder
    end
  end
end
