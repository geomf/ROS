class CreatePlanetOsmRels < ActiveRecord::Migration
  def change
    create_table :planet_osm_rels do |t|
      t.text :name
      t.integer :feeder_id, null: false
      t.text :power, null: false
      t.hstore :tags

    end
  end
end


