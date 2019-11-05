/*
	Create User used by Azure Functions
*/
CREATE USER [demo] WITH PASSWORD = 'AVery?STRONGPa22W0rd!';
ALTER ROLE [db_owner] ADD MEMBER [demo]
GO
