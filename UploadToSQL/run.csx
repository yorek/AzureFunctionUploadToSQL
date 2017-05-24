#r "Microsoft.WindowsAzure.Storage"
#r "System.Data"

using System;
using System.Net;
using System.Net.Mail;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using Microsoft.Azure.WebJobs.Host;
using Microsoft.WindowsAzure.Storage.Blob;
using Dapper;

public static void Run(CloudBlockBlob blob, TraceWriter log)
{
    string content = blob.DownloadText();
    string containerName = blob.Container.Name;
    string fileName = blob.Name;

    string azureSQLConnectionString = ConfigurationManager.ConnectionStrings["SQLAzure"]?.ConnectionString;

    if (!fileName.EndsWith(".csv"))
    {
        log.Info($"Blob '{blob.Name}' doesn't have the .csv extension. Skipping processing.");
        return;
    }

    log.Info($"Blob '{blob.Name}' found. Uploading to SQL Server");

    SqlConnection conn = null;
    try
    {
        conn = new SqlConnection(azureSQLConnectionString);
        conn.Execute("EXEC dbo.BulkLoadFromAzure @sourceFileName", new { @sourceFileName = blob.Name }, commandTimeout: 180);
        log.Info($"Blob '{blob.Name}' uploaded");
    }
    catch (SqlException se)
    {
        log.Info($"Exception Trapped: {se.Message}");
        
        //Enable if you want to receive an email if unxpected error happens
        //SendEmail("[CSV Data SQL Uploader] Exception Trapped", se.Message);
    }
    finally
    {
        conn?.Close();
    }
}

public static void SendEmail(string subject, string message)
{
    string fromEmail = "<sender@your-domain.com>";
    string toEmail = "<receiver@your-domain.com>";
    string smtpHost = "smtp.sendgrid.net";
    string smtpUser = ConfigurationManager.AppSettings["SendGrid.Account"];
    string smtpPass = ConfigurationManager.AppSettings["SendGrid.Password"];
    int smtpPort = 587;
    bool smtpEnableSsl = true;

    using (SmtpClient client = new SmtpClient())
    {
        client.Port = smtpPort;
        client.EnableSsl = smtpEnableSsl;
        client.DeliveryMethod = SmtpDeliveryMethod.Network;
        client.UseDefaultCredentials = false;
        client.Host = smtpHost;
        client.Credentials = new System.Net.NetworkCredential(smtpUser, smtpPass);

        MailMessage mail = new MailMessage(fromEmail, toEmail);
        mail.Subject = subject;
        mail.Body = message;

        client.Send(mail);
    }
}