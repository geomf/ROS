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


