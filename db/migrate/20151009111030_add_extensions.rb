class AddExtensions < ActiveRecord::Migration
  def change
    enable_extension 'hstore'
  end
end
