# dockerfile

docker-machine使用

# host確認
$ docker-machine ls

# virtualboxを使ってhostをたてる(devの部分は任意)
$ docker-machine create --driver virtualbox dev

# Dockerfileにて作成されたimage実行
docker run -it -d -p 2222:22 -p 8080:80 --name web_base -h webm01 centos6:web1.0 /usr/bin/supervisord 


[メモ]
ここを書き換えれば固定化できるか？(試す予定)
docker-machineのconfig設定
vim ~/.docker/machine/machines/dev/config.json
