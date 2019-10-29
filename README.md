# Upload CSV to SQL Server via Azure Function

A sample template that allows to upload the content of a CSV file to a Azure SQL database as soon as the .csv file is dropped in an Azure Blob Store. Full article is here:

[Automatic import of CSV data using Azure Functions and Azure SQL](https://medium.com/@mauridb/automatic-import-of-csv-data-using-azure-functions-and-azure-sql-63e1070963cf)

Following there are the instructions you need to follow in order to setup the solution. [Azure CLI 2.0](https://docs.microsoft.com/en-us/cli/azure/get-started-with-azure-cli) commands are also provided as a reference

## Authenticate Azure CLI 2.0

Login with your account

    az login

and then select the Subscription you want to use

    az account set --subscription <your-subscription>

## Create a Resource Group

All resources of this example will be created in a dedicated Resource Group, named "CSVImportDemo"

    az group create --name CSVImportDemo --location westus

## Create Blob Storage

Create the azure storage account used by Azure Function and to drop in our CSV files to be automatically imported

    az storage account create --name csvimportdemo --location westus --resource-group CSVImportDemo --sku Standard_LRS

Once this is done get the account key and create a container named 'csv':

    az storage container create --account-name csvimportdemo --account-key <your-account-key> --name csv

Generate also Shared Access Signature (SAS) key token and store it for later use. The easies way to do this is to use [Azure Storage Explorer](https://azure.microsoft.com/en-us/features/storage-explorer/).

Otherwise you can do it via AZ CLI using the `az storage account generate-sas` command.

## Create and Deploy the function app

The easiest way to install, build and deploy the sample Function App, is to use [Visual Studio Code](https://code.visualstudio.com/). It will automatically detect that the `.csproj` is related to a FUnction App, will download the Function App runtime and also recommend you to download the Azure Function extension.

Once the project is loaded, add the `AzureSQL` configuration to your `local.settings.json` file:

    "AzureSQL": "<sql-azure-connection-string>"

Also make sure that the Function App is correctly monitoring the Azure Storage Account where you plan to drop you CSV files. If you used Visual Studio code, this should have already been set up for you. If not make sure you have the 'AzureStorage' configuration element in your `local.settings.json` file and that it has the connection string for the Azure Blob Storage account you want to use:

    "AzureStorage": "DefaultEndpointsProtocol=https;AccountName=csvimportdemo;AccountKey=[account-key-here];EndpointSuffix=core.windows.net"

## Create Azure SQL Server and Database

Create an Azure SQL Server:

    az sql server create --name csvimportdemo --resource-group CSVImportDemo --location westus --admin-user csvimportdemo --admin-password csvimportdemoPassw0rd!

Via the Azure Portal make sure that the firewall is configure to "Allow access to Azure Services".

Also a small Azure SQL Database:

    az sql db create --name CSVImportDemo --resource-group CSVImportDemo --server csvimportdemo

## Upload format file

Behind the scenes, the solution uses the T-SQL `BULK INSERT` command to import data read from a .csv file. In order to work the command needs a format file named `csv.fmt` in the `csv` container.

    az storage blob upload --container-name csv --file SQL\csv.fmt --name csv.fmt --account-name csvimportdemo --account-key <your-account-key>

As mentioned before, the easiest way is to use [Azure Storage Explorer](https://azure.microsoft.com/en-us/features/storage-explorer/).

## Configure Bulk Load Security

Connect to the created Azure SQL database and execute the script to configure access to blob store for Azure SQL. The script is available here

`sql/enable-bulk-load.sql`

just customize it with your own info before running it.

Please not that when you specific the SAS key token, you have to remove the initial question mark (?) that is automatically added
when you create the SAS key token online.

## Create Database Objects

In the Azure SQL database couple of tables and a stored procedures needs also to be created in order to have the sample working correctly.

Scripts to create the mentioned objects are available in

`sql/create-objects.sql`

Just execute it against the Azure SQL database.

## Deploy and Run the Function App

You can now run the Function app on your machine, or you can deploy using Visual Studio Code and its Azure Function extension. Or you can use `az functionapp` to deploy the function manually.

## Test the solution

All the CSV  file that will be copied into the `csv` container will be loaded into Azure SQL and specifically into the following tables:

- File
- FileData

To test the everything works copy the `test.csv` file to Azure:

    az storage blob upload --container-name csv --file SQL\test.csv --name test.csv --account-name csvimportdemo --account-key <your-account-key>

if you open Function App Log you will see that the function has been invoked or, if you're running the function locally on your machine, you will see the log directly on the console. You will find the content of the `test.csv'` file into Azure SQL.
