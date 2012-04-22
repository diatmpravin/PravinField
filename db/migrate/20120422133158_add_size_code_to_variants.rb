class AddSizeCodeToVariants < ActiveRecord::Migration
  def change
    add_column :variants, :size_code, :string
  end
end
