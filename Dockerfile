# Unified Build for JM-Backend Services
# Optimized for Docker layer caching - dependencies cached separately from source code
FROM eclipse-temurin:17-jdk AS builder
WORKDIR /app

# ========== Stage 1: Copy Maven Wrapper and POM files first (rarely change) ==========
# Copy Maven Wrapper from one of the sub-modules to use at root
COPY JM-CompanyAuthService/.mvn .mvn
COPY JM-CompanyAuthService/mvnw mvnw
COPY JM-CompanyAuthService/mvnw.cmd mvnw.cmd

# Grant execution permission
RUN chmod +x mvnw

# Copy root POM
COPY pom.xml ./pom.xml

# Copy ALL module POMs (required for Maven to resolve multi-module structure)
# SG-SharedDtoPackage
COPY SG-SharedDtoPackage/pom.xml ./SG-SharedDtoPackage/pom.xml

# JM-CompanyAuthService (multi-module)
COPY JM-CompanyAuthService/pom.xml ./JM-CompanyAuthService/pom.xml
COPY JM-CompanyAuthService/CompanyAuthApi/pom.xml ./JM-CompanyAuthService/CompanyAuthApi/pom.xml
COPY JM-CompanyAuthService/CompanyAuthService/pom.xml ./JM-CompanyAuthService/CompanyAuthService/pom.xml

# JM-CompanyProfileService (multi-module)
COPY JM-CompanyProfileService/pom.xml ./JM-CompanyProfileService/pom.xml
COPY JM-CompanyProfileService/CompanyProfileApi/pom.xml ./JM-CompanyProfileService/CompanyProfileApi/pom.xml
COPY JM-CompanyProfileService/CompanyProfileService/pom.xml ./JM-CompanyProfileService/CompanyProfileService/pom.xml

# JM-ApplicantDiscoveryService (multi-module)
COPY JM-ApplicantDiscoveryService/pom.xml ./JM-ApplicantDiscoveryService/pom.xml
COPY JM-ApplicantDiscoveryService/ApplicantDiscoveryApi/pom.xml ./JM-ApplicantDiscoveryService/ApplicantDiscoveryApi/pom.xml
COPY JM-ApplicantDiscoveryService/ApplicantDiscoveryService/pom.xml ./JM-ApplicantDiscoveryService/ApplicantDiscoveryService/pom.xml

# JM-Eureka
COPY JM-Eureka/pom.xml ./JM-Eureka/pom.xml

# JM-Gateway
COPY JM-Gateway/pom.xml ./JM-Gateway/pom.xml

# Copy settings.xml for GitHub packages access
COPY JM-CompanyAuthService/settings.xml /

# ========== Stage 2: Download dependencies (cached unless POM changes) ==========
RUN --mount=type=secret,id=GITHUB_USERNAME,env=GITHUB_USERNAME,required=true  \
    --mount=type=secret,id=GITHUB_KEY,env=GITHUB_KEY,required=true \
    --mount=type=cache,target=/root/.m2 \
    cp /settings.xml /root/.m2 && \
    ./mvnw dependency:go-offline -U -pl JM-CompanyAuthService/CompanyAuthService,JM-CompanyProfileService/CompanyProfileService -am

# ========== Stage 3: Copy source code (changes frequently) ==========
# Copy shared DTO package first
COPY SG-SharedDtoPackage/src ./SG-SharedDtoPackage/src

# Copy Auth Service source
COPY JM-CompanyAuthService/CompanyAuthApi/src ./JM-CompanyAuthService/CompanyAuthApi/src
COPY JM-CompanyAuthService/CompanyAuthService/src ./JM-CompanyAuthService/CompanyAuthService/src

# Copy Profile Service source
COPY JM-CompanyProfileService/CompanyProfileApi/src ./JM-CompanyProfileService/CompanyProfileApi/src
COPY JM-CompanyProfileService/CompanyProfileService/src ./JM-CompanyProfileService/CompanyProfileService/src

# ========== Stage 4: Build (only recompiles, dependencies already cached) ==========
RUN --mount=type=cache,target=/root/.m2 \
    ./mvnw package -DskipTests -pl JM-CompanyAuthService/CompanyAuthService,JM-CompanyProfileService/CompanyProfileService -am

# ========== Runtime Stage: Minimal image with only JARs ==========
FROM eclipse-temurin:17-jre AS runner
WORKDIR /app

# Copy the compiled artifacts
COPY --from=builder /app/JM-CompanyAuthService/CompanyAuthService/target/*.jar auth-service.jar
COPY --from=builder /app/JM-CompanyProfileService/CompanyProfileService/target/*.jar profile-service.jar

# The entrypoint will be defined by the command in docker-compose
