require 'chef/provisioning/azurerm/azure_resource'

# MSDN Ref: https://msdn.microsoft.com/en-us/library/azure/mt163564.aspx

class Chef
  class Resource
    class AzureBlobContainer < Chef::Provisioning::AzureRM::AzureResource
      resource_name :azure_blob_container
      actions :create, :destroy, :nothing
      default_action :create
      attribute :name, kind_of: String, name_attribute: true, regex: /^[\w]{3,24}$/i
      attribute :storage_account_name, kind_of: String
      attribute :resource_group, kind_of: String
      attribute :access, kind_of: String, equal_to: %w(private container blob), default: 'private'
    end
  end
end
