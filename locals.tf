locals {
  backends = {
    Requestor = {
      hostnames = ["requestor.internal.local"]
      port      = 8080
      #  # Static Apache test (will use "/api/healthz" once implemented with actual image )
      health_path = "/"
      #health_path = "/health" 

      priority = 10
    }
    Worker = {
      hostnames = ["worker.internal.local"]
      port      = 9090
      # Static Apache test (will use "/api/healthz" once implemented with actual image )
      health_path = "/"
      #health_path = "/api/healthz"

      priority = 20
    }
    Administrator = {
      hostnames = ["administrator.internal.local"]
      port      = 7070
      # Keep as-is; change to "/" if you’re testing static HTML
      health_path = "/status"
      #health_path = "/status"  
      priority = 30
    }
  }

  hosts = ["requestor", "worker", "administrator"]
}
