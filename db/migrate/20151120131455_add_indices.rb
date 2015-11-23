class AddIndices < ActiveRecord::Migration
  def change
    add_index :planet_osm_ways, :tags, using: :gin
    add_index :planet_osm_rels, :tags, using: :gin
  end
end
