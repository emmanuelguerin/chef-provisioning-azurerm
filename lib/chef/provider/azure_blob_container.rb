require 'chef/provisioning/azurerm/azure_provider'
require 'azure/storage'

class Chef
  class Provider
    class AzureBlobContainer < Chef::Provisioning::AzureRM::AzureProvider
      provides :azure_blob_container

      def whyrun_supported?
        true
      end

      action :create do
        # Does the storage account already exist in the specified resource group?
        blobs = get_blob_client
        container = blobs.list_containers(prefix: new_resource.name).select { |c| c.name == new_resource.name }.first
        unless container
          converge_by("create blob container #{new_resource.name} in #{new_resource.storage_account_name}") do
            options = {}
            options[:public_access_level] = new_resource.access if new_resource.access != 'private'
            blobs.create_container(new_resource.name, options)
          end
        else
          converge_by("update blob container #{new_resource.name} in #{new_resource.storage_account_name}") do
            public_access_level = ''
            public_access_level = new_resource.access if new_resource.access != 'private'
            blobs.set_container_acl(new_resource.name, public_access_level)
          end
        end
      end

      action :destroy do
        converge_by("destroy blob container: #{new_resource.name} in #{new_resource.storage_account_name}") do
          blobs = get_blob_client
          container = blobs.list_containers(prefix: new_resource.name).select { |c| c.name == new_resource.name }.first
          if container
            action_handler.report_progress 'destroying blob container'
            blobs.delete_container(new_resource.name)
          else
            action_handler.report_progress "blob container #{new_resource.name} was not found in #{new_resource.storage_account_name}."
          end
        end
      end

      def get_blob_client
        result = storage_management_client.storage_accounts.list_keys_async(new_resource.resource_group, new_resource.storage_account_name).value!
        access_key = result.body.keys[0].value

        storage_client = Azure::Storage::Client.create(storage_account_name: new_resource.storage_account_name, storage_access_key: access_key)
        blob_client = storage_client.blob_client
      end
    end
  end
end
