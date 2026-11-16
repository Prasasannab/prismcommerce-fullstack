# Multi-stage build for PrismCommerce ASP.NET Core 8 Web API
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy project files first for layer caching
COPY ["PrismCommerce.Domain/PrismCommerce.Domain.csproj", "PrismCommerce.Domain/"]
COPY ["PrismCommerce.Application/PrismCommerce.Application.csproj", "PrismCommerce.Application/"]
COPY ["PrismCommerce.Infrastructure/PrismCommerce.Infrastructure.csproj", "PrismCommerce.Infrastructure/"]
COPY ["PrismCommerce.Api/PrismCommerce.Api.csproj", "PrismCommerce.Api/"]
COPY ["PrismCommerce.sln", "./"]

RUN dotnet restore "PrismCommerce.sln"

# Copy full source and build release artifacts
COPY . .
WORKDIR "/src/PrismCommerce.Api"
RUN dotnet publish "PrismCommerce.Api.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Runtime image
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
EXPOSE 8080
ENV ASPNETCORE_HTTP_PORTS=8080
ENV ASPNETCORE_ENVIRONMENT=Development

COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "PrismCommerce.Api.dll"]
