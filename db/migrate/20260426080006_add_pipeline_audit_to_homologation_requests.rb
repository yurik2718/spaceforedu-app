class AddPipelineAuditToHomologationRequests < ActiveRecord::Migration[8.1]
  def change
    add_column :homologation_requests, :pipeline_changed_at, :datetime
    add_column :homologation_requests, :pipeline_changed_by, :integer

    add_index :homologation_requests, :pipeline_changed_at
    add_foreign_key :homologation_requests, :users, column: :pipeline_changed_by
  end
end
