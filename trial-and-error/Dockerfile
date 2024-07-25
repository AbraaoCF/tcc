# Start from the official Go 1.22 image for building the Go app
FROM golang:1.22 AS builder

# Set the working directory inside the container
WORKDIR /app

# Copy the Go module files and download the dependencies
COPY go.mod go.sum ./
RUN go mod download

# Copy the source code into the container
COPY . .

# Build the Go application
RUN go build -o opa_redis_logger .

# Start a new stage from a Debian-based image
FROM debian:latest

# Set the working directory inside the container
WORKDIR /root/

# Install necessary packages
RUN apt-get update && apt-get install -y ca-certificates

# Copy the compiled binary from the builder stage
COPY --from=builder /app/opa_redis_logger .

# Ensure the binary is executable
RUN chmod +x ./opa_redis_logger

# Specify the command to run the binary
CMD ["./opa_redis_logger"]
