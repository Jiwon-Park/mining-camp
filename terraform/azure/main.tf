terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.0.0"
    }
  }
}

data "azurerm_subscription" "current" {

}

provider "azurerm" {
  features {}
}


resource "azurerm_resource_group" "minecraft" {
  name = "minecraft-resources"
  location = "Korea Central"
}

resource "azurerm_virtual_network" "minecraft" {
  name = "minecraft-network"
  resource_group_name = azurerm_resource_group.minecraft.name
  location = azurerm_resource_group.minecraft.location
  address_space = [ "10.0.0.0/24" ]
}

resource "azurerm_subnet_service_endpoint_storage_policy" "tostorage" {
  location = azurerm_resource_group.minecraft.location
  resource_group_name = azurerm_resource_group.minecraft.name
  name = "minecraftBackupPolicy"
  
  definition {
    name = "minecraft-storage"
    description = "Allow Minecraft VMs to access storage accounts"
    
    service_resources = [
      # azurerm_resource_group.minecraft.id,
      azurerm_storage_account.minecraft.id
    ]
  }
}

resource "azurerm_subnet" "internal" {
  name = "internal"
  resource_group_name = azurerm_resource_group.minecraft.name
  virtual_network_name = azurerm_virtual_network.minecraft.name
  address_prefixes = [ "10.0.0.0/25" ]
  service_endpoints = [ "Microsoft.Storage" ]
  service_endpoint_policy_ids = [ azurerm_subnet_service_endpoint_storage_policy.tostorage.id ]
}

data "azurerm_ssh_public_key" "sshkey" {
  name = "minecraftserver-sshkey"
  resource_group_name = azurerm_resource_group.minecraft.name
}

resource "azurerm_linux_virtual_machine_scale_set" "minecraft" {
  name = "minecraft-server"
  resource_group_name = azurerm_resource_group.minecraft.name
  location = azurerm_resource_group.minecraft.location
  sku = "Standard_D2as_v4"
  instances = 0
  network_interface {
    name = "minecraft-nic"
    primary = true
    ip_configuration {
      name = "internal"
      subnet_id = azurerm_subnet.internal.id
      public_ip_address {
        name = "minecraft-public-ip"
      }
    }
  }
  admin_username = "ubuntu"
  admin_ssh_key {
    username = "ubuntu"
    public_key = data.azurerm_ssh_public_key.sshkey.public_key
  }
  os_disk {
    disk_size_gb = 30
    storage_account_type = "StandardSSD_LRS"
    caching = "ReadWrite"
  }
  priority = "Spot"
  eviction_policy = "Delete"
  max_bid_price = "0.02"
  source_image_reference {
    publisher = "Canonical"
    offer = "0001-com-ubuntu-server-jammy"
    sku = "22_04-lts-gen2"
    version = "latest"
  }

}

resource "azurerm_storage_account" "minecraft" {
  location = azurerm_resource_group.minecraft.location
  resource_group_name = azurerm_resource_group.minecraft.name
  account_tier = "Standard"
  account_replication_type = "LRS"
  name = "wldnjs1323storage"
}

resource "azurerm_storage_container" "minecraft" {
  name = "minecraftbackup"
  storage_account_name = azurerm_storage_account.minecraft.name
  container_access_type = "private"
}

# resource "azurerm_storage_blob" "backup" {
#   type = ""
#   name = "minecraft-backup"
#   storage_account_name = azurerm_storage_account.minecraft.name
#   storage_container_name = azurerm_storage_container.minecraft.name
# }