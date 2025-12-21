# Unified Build for JM-Backend Services
FROM eclipse-temurin:17-jdk AS builder
WORKDIR /app

# Copy Maven Wrapper from one of the sub-modules to use at root
COPY JM-CompanyAuthService/.mvn .mvn
COPY JM-CompanyAuthService/mvnw mvnw
COPY JM-CompanyAuthService/mvnw.cmd mvnw.cmd

# Copy the entire project
COPY . .

# Grant execution permission
RUN chmod +x mvnw

# Build specific services and their dependencies (including SG-SharedDtoPackage)
# Using directory paths for clarity
RUN ./mvnw clean package -DskipTests -pl JM-CompanyAuthService/CompanyAuthService,JM-CompanyProfileService/CompanyProfileService -am

# Runtime Stage
FROM eclipse-temurin:17-jdk AS runner
WORKDIR /app

# Copy the compiled artifacts
# Using wildcard but expecting only one main jar per target
COPY --from=builder /app/JM-CompanyAuthService/CompanyAuthService/target/*.jar auth-service.jar
COPY --from=builder /app/JM-CompanyProfileService/CompanyProfileService/target/*.jar profile-service.jar

# The entrypoint will be defined by the command in docker-compose
