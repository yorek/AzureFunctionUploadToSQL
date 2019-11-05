/*
	Create a database Master Key to store credentials
*/
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'A-$tr0ng|PaSSw0Rd!';
GO

/*
	Create a crendential to store SAS key.
	To get the SAS key either use Azure Storage Explorer 
	or AZ CLI:
	az storage account generate-sas --account-name <account-name> --permissions rl --services b --resource-types sco --expiry 2020-01-01

*/
CREATE DATABASE SCOPED CREDENTIAL [Storage-Credentials]
WITH IDENTITY = 'SHARED ACCESS SIGNATURE',
SECRET = ''; -- without leading "?"
GO

SELECT * FROM sys.[database_scoped_credentials]
GO

/*
	Create external data source
*/
CREATE EXTERNAL DATA SOURCE [Azure-Storage]
WITH 
( 
	TYPE = BLOB_STORAGE,
 	LOCATION = 'https://<account-name>.blob.core.windows.net',
 	CREDENTIAL= [Storage-Credentials]
);

SELECT * FROM sys.[external_data_sources]
GO

