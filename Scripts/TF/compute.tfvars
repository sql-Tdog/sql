dcdb_sql_3 = [
    {
      name                         = "VM"
      osType                       = "Windows"
      count                        = 1
      zones                        = [1]
      sku                          = "Standard_E48ds_v5"
      os_disk_storage_account_type = "Premium_LRS"
      ultra_ssd_enabled            = true
      disk_size                    = 200
      data_disks = {
        "Binaries" : {
          "create_option" : "Empty",
          "storage_account_type" : "PremiumV2_LRS",
          "disk_size_gb" : 128,
          "caching" : "None",
          "lun" : 0
        },
        "TempDb" : {
          "create_option" : "Empty",
          "storage_account_type" : "PremiumV2_LRS",
          "disk_size_gb" : 1024,
          "disk_iops_read_write" : 6000,
          "disk_mbps_read_write" : 150,
          "caching" : "None", 
          "lun" : 1
        },
        "Log" : {
          "create_option" : "Empty",
          "storage_account_type" : "PremiumV2_LRS",
          "disk_size_gb" : 1024,
          "disk_iops_read_write" : 6000,
          "disk_mbps_read_write" : 400,
          "caching" : "None",
          "lun" : 2
        },
        "Data_1" : {
          "create_option" : "Empty",
          "storage_account_type" : "PremiumV2_LRS",
          "disk_size_gb" : 7189,
          "disk_iops_read_write" : 22000,
          "disk_mbps_read_write" : 800,
          "caching" : "None",
          "lun" : 3
        },
        "Data_2" : {
          "create_option" : "Empty",
          "storage_account_type" : "PremiumV2_LRS",
          "disk_size_gb" : 7189,
          "disk_iops_read_write" : 22000,
          "disk_mbps_read_write" : 800,
          "caching" : "None",
          "lun" : 4
        },
        "Data_3" : {
          "create_option" : "Empty",
          "storage_account_type" : "PremiumV2_LRS",
          "disk_size_gb" : 7189,
          "disk_iops_read_write" : 22000,
          "disk_mbps_read_write" : 800,
          "caching" : "None",
          "lun" : 5
        }
      }
      image                 = "esign_windows_server_2019"
      multi_subnet_override = ["sql-1"]
      network_interface_cards = {
        "primary_nic" = {
          ip_configurations = {
            "primary"   = {}
            "secondary" = {}
          }
        }
      }
      sql_configuration = {
        sql_license_type = "DR"
      }
    }
  ]