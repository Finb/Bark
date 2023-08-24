
## Docker 
```
docker run -dt --name bark -p 8080:8080 -v `pwd`/bark-data:/data finab/bark-server
```

## Docker-Compose 
```
mkdir bark && cd bark
curl -sL https://git.io/JvSRl > docker-compose.yaml
docker-compose up -d
```
## Manual Deployment

1. Download executable files based on operating system platform. <br> <a href='https://github.com/Finb/bark-server/releases'>https://github.com/Finb/bark-server/releases</a><br>
Or compile it yourself. <br>
<a href="https://github.com/Finb/bark-server">https://github.com/Finb/bark-server</a>

2. Run
```
./bark-server_linux_amd64 -addr 0.0.0.0:8080 -data ./bark-data
```
3. You may need to do
```
chmod +x bark-server_linux_amd64
```
Please note that bark-server defaults to using the /data directory to save data. Please make sure that bark-server has permission to read and write the /data directory, or you can use the -data option to specify a directory.

## Test
```
curl http://0.0.0.0:8080/ping
```
If it returns pong, it means the deployment was successful

