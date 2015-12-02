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
