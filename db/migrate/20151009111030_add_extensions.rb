class AddExtensions < ActiveRecord::Migration
  def change
    enable_extension 'hstore'
    enable_extension 'postgis'
  end
end
