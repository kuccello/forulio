class CreateBlackIps < ActiveRecord::Migration
  def self.up
    create_table :black_ips do |t|
      t.string :ip
      t.timestamps
    end
  end

  def self.down
    drop_table :black_ips
  end
end
