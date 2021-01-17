using System;
using System.IO;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json.Linq;

namespace Example.Functions
{
    public static class Check
    {
        [FunctionName("Check")]
        public static async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Anonymous, "get", "post", Route = null)] HttpRequest req,
            ILogger log)
        {
            string host = Environment.GetEnvironmentVariable("StorageWebHostForFunc");
            IPAddress[] addresses = Dns.GetHostAddresses(host);

            string responseMessage = JObject.FromObject(new {
                host = host,
                ipAddresses = addresses.Select(ip => ip.ToString()).ToArray(),
            }).ToString();

            return new OkObjectResult(responseMessage);
        }
    }
}
