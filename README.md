# Upload CSV to SQL Server via Azure Function

A sample template that allows to upload the content of a CSV file to a Azure SQL database as soon as the .csv file is dropped in an Azure Blob Store.
Following are the instructions you need to follow in order to setup the solution. [Azure CLI 2.0](https://docs.microsoft.com/en-us/cli/azure/get-started-with-azure-cli) commands are also provided as a reference

## Autenticate Azure CLI 2.0

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

Generate also Shared Access Signature (SAS) key token and store it for later use

## Create the Function App

At present time Function App cannot be created via the Azure Portal, and you have to do it via Azure CLI:

    az functionapp create --name CSVImportDemo --storage-account csvimportdemo --consumption-plan-location westus --resource-group CSVImportDemo

## Configure Function App Settings

From the Azure Portal you have to create the following Application Settings for the Function App (Function App is accessible from the App Services blade):

- SendGrid.Account: `<your-sendgrid-account>`,
- SendGrid.Password: `<your-sendgrid-account-password>`,

The above values are needed only if you want to receive and email if an unhandled exception happes. In that case you also have to

- Have a working SendGrid service
- Uncomment line 42 in `run.csx`

and you also the followin connection string is needed:

- SQLAzure: `<sql-azure-connection-string>`

please remember to create that key-value pair in the *Connection String* section.

## Create Azure SQL Server and Database

Create an Azure SQL Server:

    az sql server create --name csvimportdemo --resource-group CSVImportDemo --location westus --admin-user csvimportdemo --admin-password csvimportdemoPassw0rd

Via the Azure Portal make sure that the firewall is configure to "Allow access to Azure Services".

Also a small Azure SQL Database:

    az sql db create --name CSVImportDemo --resource-group CSVImportDemo --server csvimportdemo --service-objective Basic

## Upload format file

Behind the scenes, the solution uses the T-SQL `BULK INSERT` command to import data read from a .csv file. In order to work the command needs a format file named `csv.fmt` in the `csv` container. 

    az storage blob upload --container-name csv --file SQL\csv.fmt --name csv.fmt --account-name csvimportdemo --account-key <your-account-key>

## Configure Bulk Load Security

Connect to the created Azuer SQL database and execute the script to configure access to blob store for Azure SQL. The script isavailabe here

`sql/enable-bulk-load.sql`

just customize it with your own info befure running it.

Please not that when you specifict the SAS key token, you have to remove the initial question mark (?) that is automatically added
when you create the SAS key token online.

## Create Database Objects

In the Azure SQL database couple of tables and a stored procedures needs also to be created in order to have the sample worlking correctly.

Scripts to create the mentioned objects are available in

`sql/create-objects.sql`

Just execute it agains the Azure SQL database.

## Create a Function App function

From the Azure Portal, go to the Function App blad and create a new fuction named `UploadToSQL` starting from the "BlobTrigger-CSharp" template. After that copy the content of the local `UploadToSQL` folder into the function, replacing the file if they already exists.

Once everything is saved, that function should compile nicely (check the log to make sure of that).

## Test the solution

All the CSV  file that will be copied into the `csv` container will be loaded into Azure SQL and specifically into the 

- File
- FileData

tables. To test the everything works copy the `test.csv` file to Azure:

    az storage blob upload --container-name csv --file SQL\test.csv --name test.csv --account-name csvimportdemo --account-key <your-account-key>

if you open Function App Log you will see that the function has been invoked. You will find the content of the `test.csv'` file into Azure SQL.
