# The `terraform` block is used to configure Terraform's behavior.
# It includes settings like required provider versions, which ensures that anyone
# running this code uses a compatible version of the Docker provider.
terraform {
  # The `required_providers` block specifies which providers are necessary
  # for this configuration to work. Providers are plugins that Terraform uses
  # to interact with cloud providers, SaaS providers, and other APIs.
  required_providers {
    # This line declares a requirement for the "docker" provider.
    # The key "docker" is the local name we will use throughout the configuration
    # to refer to this provider.
    docker = {
      # The `source` attribute specifies the global address of the provider.
      # This tells Terraform where to download it from. "kreuzwerker/docker" is a
      # popular and well-maintained Docker provider developed by the community.
      source = "kreuzwerker/docker"

      # The `version` attribute defines the version constraints for the provider.
      # "~> 3.0.1" is a pessimistic version constraint. It means Terraform can use
      # version 3.0.1 or any later patch release within the 3.0 minor release (e.g., 3.0.2),
      # but it will not upgrade to version 3.1.0 or higher. This prevents breaking
      # changes from being introduced automatically.
      version = "~> 3.0.1"
    }
  }
}

# The `provider` block configures a specific provider, in this case, "docker".
# After being declared in the `required_providers` block, it must be configured.
# This block is where you would typically add authentication details or other
# provider-specific settings (like the Docker host address). Since this block
# is empty, the provider will use default settings, such as connecting to the
# Docker daemon on the local machine via its default socket.
provider "docker" {}

# This `resource` block declares a resource to be managed by Terraform.
# The resource type is "docker_network", which means Terraform will manage a Docker network.
# "app_network" is the local name given to this specific resource within the Terraform code.
# We will use this name to refer to this network in other parts of the configuration.
resource "docker_network" "app_network" {
  # The `name` argument specifies the actual name of the Docker network that will be created.
  # When you run `docker network ls`, you will see a network named "terraform_network".
  name = "terraform_network"
}

# This `resource` block manages a Docker image.
# The resource type is "docker_image", and its local name in Terraform is "nginx".
resource "docker_image" "nginx" {
  # The `name` argument specifies the name and tag of the image to pull from a registry.
  # "nginx:latest" tells Docker to find the image named "nginx" with the "latest" tag.
  # By default, it will pull from Docker Hub.
  name = "nginx:latest"

  # The `keep_locally` argument determines whether the image should be kept on the
  # local machine when the Terraform resource is destroyed.
  # By setting it to `false`, the "nginx:latest" image will be removed from your
  # local Docker image cache when you run `terraform destroy`. If it were `true`,
  # the image would remain after the resource is destroyed.
  keep_locally = false
}

# This `resource` block manages a Docker container.
# The resource type is "docker_container", and its local name is "nginx_container".
resource "docker_container" "nginx_container" {
  # The `name` argument sets the name of the container that will be created.
  # When you run `docker ps`, you will see a container named "terraform_nginx_container".
  name  = "terraform_nginx_container"

  # The `image` argument specifies which Docker image to use for this container.
  # The value `docker_image.nginx.image_id` is an expression that references the
  # `docker_image` resource named `nginx` defined above. `.image_id` is an attribute
  # of the `docker_image` resource that provides the exact image hash ID,
  # ensuring this container is created from the precise image Terraform pulled.
  image = docker_image.nginx.image_id

  # The `networks_advanced` block provides more detailed network configuration
  # than the deprecated `networks` argument. It allows connecting the container
  # to one or more networks.
  networks_advanced {
    # The `name` argument specifies the name of the network to connect the container to.
    # The value `docker_network.app_network.name` is an expression. It refers to the
    # `docker_network` resource named `app_network` and retrieves its `name` attribute
    # ("terraform_network"). This creates an explicit dependency: Terraform knows it must
    # create the network before it can create the container.
    name = docker_network.app_network.name
  }

  # The `ports` block defines the port mappings between the host machine and the container.
  ports {
    # The `internal` argument specifies the port inside the container that will be exposed.
    # The Nginx web server inside the container listens on port 80 by default.
    internal = 80

    # The `external` argument specifies the port on the host machine that will be
    # mapped to the internal port. Traffic sent to port 8080 on your local machine
    # will be forwarded to port 80 inside the container.
    external = 8080
  }
}
