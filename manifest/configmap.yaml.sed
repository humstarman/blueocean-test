apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-conf 
  namespace: {{.namespace}} 
data:
  nginx.conf: |-
    error_log stderr notice;

    worker_processes auto;
    events {
      multi_accept on;
      use epoll;
      worker_connections 1024;
    }

    stream {
        upstream kube_apiserver {
            least_conn;
            server {{.master.ip.1}}:{{.kube-apiserver.secure.port}};
            server {{.master.ip.2}}:{{.kube-apiserver.secure.port}};
            server {{.master.ip.3}}:{{.kube-apiserver.secure.port}};
        }

        server {
            listen        0.0.0.0:{{.kube-apiserver.secure.port}};
            proxy_pass    kube_apiserver;
            proxy_timeout 10m;
            proxy_connect_timeout 1s;
        }
    }
