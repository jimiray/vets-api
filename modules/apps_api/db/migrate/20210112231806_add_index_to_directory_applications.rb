# frozen_string_literal: true

class AddIndexToDirectoryApplications < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def change
    add_index 'directory_applications', :name, algorithm: :concurrently
  end
end
