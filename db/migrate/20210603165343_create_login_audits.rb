class CreateLoginAudits < ActiveRecord::Migration[6.0]
  def change
    create_table :login_audits do |t|
      t.string   :request_id
      t.integer  :account_id
      t.string   :idp
      t.string   :ip_address
      t.datetime :started_at
      t.datetime :completed_at
      t.boolean  :success # Was the request successful
      t.text     :response
      t.timestamps
    end
  end
end