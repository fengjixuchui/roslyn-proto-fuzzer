FROM mcr.microsoft.com/dotnet/core/sdk:2.2 AS build-env
WORKDIR /app

ENV PATH="${PATH}:/root/.dotnet/tools"
RUN dotnet tool install --global SharpFuzz.CommandLine

RUN wget -qO - https://github.com/Metalnem/roslyn-proto-fuzzer/releases/latest/download/libfuzzer-proto-dotnet.tar.gz | tar -xz

COPY src/*.csproj ./
RUN dotnet restore

COPY src/*.cs ./
RUN dotnet publish -c release -o out \
	&& sharpfuzz out/Microsoft.CodeAnalysis.dll \
	&& sharpfuzz out/Microsoft.CodeAnalysis.CSharp.dll

FROM mcr.microsoft.com/dotnet/core/runtime:2.2
WORKDIR /app

COPY --from=build-env /app/libfuzzer-proto-dotnet /app/out ./

ENTRYPOINT ["./libfuzzer-proto-dotnet", "--target_path=./Roslyn.Fuzz", "corpus"]
