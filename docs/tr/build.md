## Kaynak Kodu İndirme
GitHub'dan kaynak kodunu indirin: [bark-server](https://github.com/Finb/bark-server)

veya
```sh
git clone https://github.com/Finb/bark-server.git
```
## Gerekli Bağımlılıkları Yapılandırma
- Golang 1.18+
- Go Mod (env GO111MODULE=on)
- Go Mod Proxy (env GOPROXY=https://goproxy.cn)
- [go-task](https://taskfile.dev/installation/) kurulu olmalı.

## Tüm Platformlar İçin Çapraz Derleme
```sh
task
```

## Belirli Bir Platform İçin Derleme
```sh
task linux_amd64
task linux_amd64_v3
```

## Desteklenen Platformlar

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