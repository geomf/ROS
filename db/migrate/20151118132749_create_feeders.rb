class CreateFeeders < ActiveRecord::Migration
  def change
    create_table :feeders do |t|
      t.text :name
      t.text :config, array: true
    end
  end
end
