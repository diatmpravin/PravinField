class CreateImports < ActiveRecord::Migration
  def change
    create_table :imports do |t|
      t.string :format
      t.has_attached_file :input_file
      t.has_attached_file :error_file
      t.datetime :import_date
      t.string :status

      t.timestamps
    end
  end
end
