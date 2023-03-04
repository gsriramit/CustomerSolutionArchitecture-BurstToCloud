using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;

namespace DotNetCoreSqlDb.Models
{
    public class MyDatabaseContext : DbContext
    {
        private readonly HttpContext _httpContext;
        private readonly IConfiguration _configuration;
        public MyDatabaseContext(DbContextOptions<MyDatabaseContext> options, IHttpContextAccessor httpContextAccessor, IConfiguration configuration)
            : base(options)
        {
            _httpContext = httpContextAccessor.HttpContext;
            _configuration = configuration;
        }

        protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
        {
            if (_httpContext != null)
            {
                if (_httpContext.Request.Method == "GET")
                {
                    optionsBuilder.UseSqlServer(_configuration.GetConnectionString("ReadOnlyDbConnection"));
                }
                else
                {
                    optionsBuilder.UseSqlServer(_configuration.GetConnectionString("ReadWriteDbConnection"));
                }
            }
        }

        public DbSet<DotNetCoreSqlDb.Models.Todo> Todo { get; set; }
    }
}
