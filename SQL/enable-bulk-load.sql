CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'A-$tr0ng|PaSSw0Rd!';
GO

CREATE DATABASE SCOPED CREDENTIAL [CSV-Storage-Credentials]
WITH IDENTITY = 'SHARED ACCESS SIGNATURE',
SECRET = '<shared-access-signature for "csvimportdemo" blob storage here>';
GO

CREATE EXTERNAL DATA SOURCE [CSV-Storage]
WITH 
( 
	TYPE = BLOB_STORAGE,
 	LOCATION = 'https://csvimportdemo.blob.core.windows.net',
 	CREDENTIAL= [CSV-Storage-Credentials]
);

