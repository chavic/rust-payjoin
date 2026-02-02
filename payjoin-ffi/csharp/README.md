# Payjoin C# Bindings

Welcome to the C# language bindings for the [Payjoin Dev Kit](https://payjoindevkit.org/)!

## Running Tests

Follow these steps to clone the repository and run the tests.

```shell
git clone https://github.com/payjoin/rust-payjoin.git
cd rust-payjoin/payjoin-ffi/csharp

# Generate the bindings
bash ./scripts/generate_bindings.sh

# Build the project
dotnet build

# Run all tests
dotnet test
```

## Requirements

- .NET 8.0 or higher
- `uniffi-bindgen-cs` installed (see [uniffi-bindgen-cs](https://github.com/NordSecurity/uniffi-bindgen-cs))

## Configuration

You can specify the path to `uniffi-bindgen-cs` via environment variable:
```shell
export UNIFFI_CS=/path/to/uniffi-bindgen-cs
dotnet build
```
