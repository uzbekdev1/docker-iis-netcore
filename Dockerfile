# escape=`
FROM mcr.microsoft.com/windows/servercore/iis AS base
WORKDIR /inetpub/wwwroot

# build
FROM mcr.microsoft.com/dotnet/sdk:5.0 AS build
WORKDIR /src
COPY ["DockerEnvDemo/DockerEnvDemo.csproj", "DockerEnvDemo/"]
RUN dotnet restore "DockerEnvDemo/DockerEnvDemo.csproj"
COPY . .
WORKDIR "/src/DockerEnvDemo"
RUN dotnet build "DockerEnvDemo.csproj" -c Release -o /app/build

# publish
FROM build AS publish
RUN dotnet publish "DockerEnvDemo.csproj" -c Release -o /app/publish

# deploy
FROM base AS final 
RUN powershell Remove-Item  -Force  -Recurse 'C:\inetpub\wwwroot\*';
COPY --from=publish /app/publish . 

# command
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'Continue'; $verbosePreference='Continue';"]

# feature
RUN Install-WindowsFeature Web-Windows-Auth 

# runtime
ENV DOTNET_RUNNING_IN_CONTAINER=true
ENV DOTNET_VERSION=5.0.6
ENV DOTNET_DOWNLOAD_URL=https://download.visualstudio.microsoft.com/download/pr/24847c36-9f3a-40c1-8e3f-4389d954086d/0e8ae4f4a8e604a6575702819334d703/dotnet-hosting-$DOTNET_VERSION-win.exe
ENV DOTNET_DOWNLOAD_SHA=9f48484fe0c55c3c3065e49f9cc3576bfd99703f250e5420bb3d2599af02c0380cd2f42278b9ce86088d70f19d171daa8fa9c504e14534b36c01afc282b4de1b

RUN Invoke-WebRequest $Env:DOTNET_DOWNLOAD_URL -OutFile WindowsHosting.exe; `
    if ((Get-FileHash WindowsHosting.exe -Algorithm sha512).Hash -ne $Env:DOTNET_DOWNLOAD_SHA) { `
    Write-Host 'CHECKSUM VERIFICATION FAILED!'; `
    exit 1; `
    }; `
    `
    dir c:\Windows\Installer; `
    Start-Process './WindowsHosting.exe' '/install /quiet /norestart' -Wait; `
    Remove-Item -Force -Recurse 'C:\ProgramData\Package Cache\*'; `
    Remove-Item -Force -Recurse 'C:\Windows\Installer\*'; `
    Remove-Item -Force WindowsHosting.exe
RUN setx /M PATH $($Env:PATH + ';' + $Env:ProgramFiles + '\dotnet')

# iis
ENV IIS_ROOT=C:\Windows

RUN `
    & $Env:IIS_ROOT\system32\inetsrv\appcmd.exe unlock config -section:system.webServer/security/authentication/windowsAuthentication;  `
    & $Env:IIS_ROOT\system32\inetsrv\appcmd.exe unlock config -section:system.webServer/security/authentication/anonymousAuthentication;	`
    & $Env:IIS_ROOT\system32\inetsrv\appcmd.exe unlock config -section:system.webServer/security/authentication/anonymousAuthentication;	`
    & $Env:IIS_ROOT\system32\inetsrv\appcmd.exe set config 'Default Web Site' -section:system.webServer/security/authentication/anonymousAuthentication /enabled:'True' /commit:apphost; `
    & $Env:IIS_ROOT\system32\inetsrv\appcmd.exe set config 'Default Web Site' -section:system.webServer/security/authentication/windowsAuthentication /enabled:'True' /commit:apphost; 

