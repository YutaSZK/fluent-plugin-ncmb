fluent-plugin-ncmb: fluentd plugin for NIFTYCloud-mbaas
====

## NIFTY Cloud mobile backend
[mBaaSでサーバー開発不要！ | ニフティクラウド mobile backend](http://mb.cloud.nifty.com/)


## Installation

```
$ gem install fluent-plugin-ncmb
```

## Usage

### input configulation

```
<source>
  type                ncmb
  tag                 TAG
  application_key     YOUR_APPLICATION_KEY
  client_key          YOUR_CLIENT_KEY
  class_name          CLASS_NAME
  api_version         YYYY-MM-DD            (default: 2013-09-01)
  pos_file_path       POS_FILE_PATH         (default: ./pos_file)

  interval            [min]                 (default: 10)
  field               [field]               (default: all)
  start_date          YYYY-MM-DD HH:MM:SS   (default: now)
  limit               [limit]               (default: 1000)
</source>
```

### output configulation

```
<match **>
  type                ncmb
  application_key     YOUR_APPLICATION_KEY
  client_key          YOUR_CLIENT_KEY
  api_version         YYYY-MM-DD            (default: 2013-09-01)
  class_name          CLASS_NAME

  buffer_path         [path]
  failed_log_path     [path]                (defualt: /var/log/fluent/ncmb)
  buffer_chunk_limit  [byte]                (default: 32m)
  flush_interval      [second]              (default: 60)
</match>
```

## Supported Ruby Versions
- Ruby 2.1
- Ruby 2.2

## LICENSE
このプログラムのライセンスについては、LICENSEファイルをご覧ください。
