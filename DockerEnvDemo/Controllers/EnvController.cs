using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using System;

namespace DockerEnvDemo.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class EnvController : ControllerBase
    { 
        private readonly ILogger<EnvController> _logger;

        public EnvController(ILogger<EnvController> logger)
        {
            _logger = logger;
        }

        [HttpGet]
        public IActionResult Get()
        {
            var dic = Environment.GetEnvironmentVariables();

            return Ok(dic);
        }
    }
}
