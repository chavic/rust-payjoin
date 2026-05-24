# Payjoin C# Bindings

C# bindings for the [Payjoin Dev Kit](https://payjoindevkit.org/), generated from
`payjoin-ffi` with UniFFI.

The NuGet package is still prepared as a preview while the C# API stabilizes. The
first release-ready package layout targets .NET 8 and ships a managed
`Payjoin.dll` plus RID-specific native `payjoin_ffi` libraries.

## Install

```shell
dotnet add package Payjoin --prerelease
```

## Requirements

- .NET 8.0 or higher
- A supported RID native asset in the package

The first preview release matrix is:

| OS | RID | Native library |
| --- | --- | --- |
| Linux x64 | `linux-x64` | `libpayjoin_ffi.so` |
| macOS x64 | `osx-x64` | `libpayjoin_ffi.dylib` |
| Windows x64 | `win-x64` | `payjoin_ffi.dll` |

The package follows the .NET native asset layout:

- `ref/net8.0/Payjoin.dll`
- `runtimes/any/lib/net8.0/Payjoin.dll`
- `runtimes/{rid}/native/{native-library}`

## Minimal Usage

```csharp
var uri = Payjoin.Url.Parse(
    "bitcoin:12c6DSiU4Rq3P4ZxziKxzrL5LmMBrzjrJX?amount=1&pj=https://example.com?ciao");

Console.WriteLine(uri.AsString());
```

## Development

With nix, the default development shell provides the Rust toolchain, .NET 10 SDK,
and .NET 8 runtime:

```shell
nix develop -c bash payjoin-ffi/csharp/contrib/test.sh
```

Without nix:

```shell
git clone https://github.com/payjoin/rust-payjoin.git
cd rust-payjoin/payjoin-ffi/csharp

bash ./scripts/generate_bindings.sh
dotnet build Payjoin.Tests.csproj
dotnet test Payjoin.Tests.csproj
```

### Windows

```powershell
git clone https://github.com/payjoin/rust-payjoin.git
cd rust-payjoin/payjoin-ffi/csharp

powershell -ExecutionPolicy Bypass -File .\scripts\generate_bindings.ps1
dotnet build Payjoin.Tests.csproj
dotnet test Payjoin.Tests.csproj
```

Generation uses the Cargo-managed C# generator pinned in `payjoin-ffi/Cargo.toml`.
By default, development generation enables `_test-utils` to keep parity with the
test suite. Set `PAYJOIN_FFI_FEATURES` to an empty value for production bindings.

## Packaging

Build the release native asset for the current host RID:

```shell
PAYJOIN_FFI_FEATURES= bash ./scripts/build_nuget_native.sh
```

On Windows:

```powershell
$env:PAYJOIN_FFI_FEATURES = ""
powershell -ExecutionPolicy Bypass -File .\scripts\build_nuget_native.ps1
```

To pack, gather every supported RID under `artifacts/runtimes/{rid}/native/`,
generate production bindings, and run:

```shell
PAYJOIN_FFI_FEATURES= PAYJOIN_FFI_PROFILE=release bash ./scripts/generate_bindings.sh
dotnet pack Payjoin.csproj --configuration Release --output artifacts/packages
```

Validate the package in a clean sample app:

```shell
bash ./scripts/smoke_nuget_package.sh artifacts/packages 0.24.0-preview.1 linux-x64
```

CI performs the package build from release native assets and runs the smoke test
on each supported RID before publishing should be considered.
