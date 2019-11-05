using System;
using System.IO;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Host;
using Microsoft.Extensions.Logging;
using Microsoft.WindowsAzure.Storage.Blob;
using System.Configuration;
using System.Data;
using Microsoft.Data.SqlClient;
using Dapper;

namespace Microsoft.AzureSQL.Samples
{
    public static class ImportCSV
    {
        [FunctionName("ImportCSV")]
        public static void Run([BlobTrigger("csv/_auto/{name}", Connection = "AzureStorage")]Stream blob, string name, ILogger log)
        {
            log.LogInformation($"Blob trigger function processed blob: {name}, size: {blob.Length} bytes");

            string azureSQLConnectionString = Environment.GetEnvironmentVariable("AzureSQL");

            if (!name.EndsWith(".csv"))
            {
                log.LogInformation($"Blob '{name}' doesn't have the .csv extension. Skipping processing.");
                return;
            }

            log.LogInformation($"Blob '{name}' found. Uploading to Azure SQL");

            SqlConnection conn = null;
            try
            {
                conn = new SqlConnection(azureSQLConnectionString);
                conn.Execute("EXEC dbo.BulkLoadFromAzure @sourceFileName", new { @sourceFileName = name }, commandTimeout: 180);
                log.LogInformation($"Blob '{name}' uploaded");
            }
            catch (SqlException se)
            {
                log.LogError($"Exception Trapped: {se.Message}");
            }
            finally
            {
                conn?.Close();
            }
        }
    }
}
