# oclip-server-lite
oclip server 轻量版本，不依赖数据库且支持多用户

# 运行服务端

```
git clone https://github.com/oclip/oclip-server-lite.git
cd oclip-server-lite
docker-compose up -d --build
```

新增用户

```
docker exec oclip-lite oclipctrl --add username
```

删除用户

```
docker exec oclip-lite oclipctrl --del username
```

查看所有用户

```
docker exec oclip-lite oclipctrl --list
```

查看运行日志

```
docker-compose logs -f
```

默认端口为 2601 , 如果需要修改外网端口，在 `docker-compose.yml` 中修改。

# 配置客户端


Linux 为 `~/.oclip` , Windows 使用菜单 `Open Config` 编辑

```
domain=ws://192.168.0.2:2601/server
token=93ee8c86-b883-46f2-ad22-2c270376bd07
passwd=123456
```

其中 `domain` 改为自己的服务器IP和端口， `token` 在添加用户时会输出，也可以用 `--list` 命令查看。 `passwd` 为客户端设置的加密密码。
