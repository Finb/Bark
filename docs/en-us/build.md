## Download Source Code
Download the source code from GitHub [bark-server](https://github.com/Finb/bark-server)

or
```sh
git clone https://github.com/Finb/bark-server.git
```
## Configure Dependencies
- Golang 1.18+
- Go Mod (env GO111MODULE=on)
- Go Mod Proxy (env GOPROXY=https://goproxy.cn)
- Install [go-task](https://taskfile.dev/installation/) 

## Cross-Compile for All Platforms
```sh
task
```

## Compile for Specific Platforms
```sh
task linux_amd64
task linux_amd64_v3
```

## Supported Platforms

- linux_386
- linux_amd64
- linux_amd64_v2
- linux_amd64_v3
- linux_amd64_v4
- linux_armv5
- linux_armv6
- linux_armv7
- linux_armv8
- linux_mips_hardfloat
- linux_mipsle_softfloat
- linux_mipsle_hardfloat
- linux_mips64
- linux_mips64le
- windows_386.exe
- windows_amd64.exe
- windows_amd64_v2.exe
- windows_amd64_v3.exe
- windows_amd64_v4.exe
- darwin_amd64
- darwin_arm64