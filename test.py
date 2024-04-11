from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient

# Acquire a credential object
token_credential = ""
my_account_name = "wldnjs1323storage"
blob_service_client = BlobServiceClient.from_connection_string(token_credential)

#list blob contents
container_name = "minecraftbackup"
container_client = blob_service_client.get_container_client(container_name)
blob_list = container_client.list_blob_names()
print(list(blob_list))