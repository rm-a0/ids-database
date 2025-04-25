using App.Helpers;
using Oracle.ManagedDataAccess.Client;
using System;
using System.Threading.Tasks;

namespace App
{
    public class Program
    {
        public static void Main(string[] args)
        {
            EnvironmentHelper.LoadEnvironmentVariables();
            TestDatabaseConnection().Wait();
        }

        public static async Task TestDatabaseConnection()
        {
            string connectionString = Environment.GetEnvironmentVariable("DB_CONNECTION_STRING");

            if (string.IsNullOrEmpty(connectionString))
            {
                Console.WriteLine("Connection string is not available.");
                return;
            }

            try
            {
                using (var connection = new OracleConnection(connectionString))
                {
                    await connection.OpenAsync();
                    Console.WriteLine("Successfully connected to the database.");

                    // Run a basic query (you can change this to match your DB schema)
                    string query = "SELECT name FROM Product FETCH FIRST 5 ROWS ONLY";  // Example for Oracle SQL
                    using (var command = new OracleCommand(query, connection))
                    {
                        using (var reader = await command.ExecuteReaderAsync())
                        {
                            while (await reader.ReadAsync())
                            {
                                // Print out each product name
                                Console.WriteLine($"Product: {reader.GetString(0)}");
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"An error occurred while connecting to the database: {ex.Message}");
            }
        }
    }
}