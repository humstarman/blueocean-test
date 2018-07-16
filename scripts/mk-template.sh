#!/bin/bash
show_help () {
cat << USAGE
usage: $0 [ -a HA_STRATEGY ] [ -p PV ] [ -o OUTPUT-FILE ]
    -a : Specify the HA strategy, for instance: "vip" or "nginx".
    -p : Using presistent volume or not, no pv used by default. 
    -o : Specify the output file path.
USAGE
exit 0
}
# Get Opts
PV="false"
while getopts "ha:po:" opt; do # 选项后面的冒号表示该选项需要参数
    case "$opt" in
    h)  show_help
        ;;
    a)  HA=$OPTARG # 参数存在$OPTARG中
        ;;
    p)  PV=true
        ;;
    o)  OUT=$OPTARG
        ;;
    ?)  # 当有不认识的选项的时候arg为?
        echo "unkonw argument"
        exit 1
        ;;
    esac
done
[ -z "$*" ] && show_help
chk_var () {
if [ -z "$2" ]; then
  echo "$(date -d today +'%Y-%m-%d %H:%M:%S') - [ERROR] - no input for \"$1\", try \"$0 -h\"."
  sleep 3
  exit 1
fi
}
chk_var -a $HA
chk_var -o $OUT
HA=$(echo $HA | tr '[:lower:]' '[:upper:]')
cat > $OUT <<EOF
kind: Deployment 
apiVersion: extensions/v1beta1
metadata:
  namespace: {{.namespace}} 
  name: {{.name}}
spec:
  replicas: 1
  template:
    metadata:
      labels:
        component: {{.name}}
    spec:
      containers:
EOF
if [[ "NGINX" == "${HA}" ]]; then
  cat >> $OUT <<EOF
        - name: proxy 
          image: nginx:stable 
          ports:
            - containerPort: {{.kube-apiserver.secure.port}}
          volumeMounts:
            - name: nginx-conf
              mountPath: /etc/nginx
EOF
fi
cat >> $OUT <<EOF
        - name: {{.name}}
          image: {{.image}} 
          ports:
            - containerPort: {{.kube-apiserver.insecure.port}}
          env:
            - name: HOST_IP
              valueFrom:
                fieldRef:
                  fieldPath: status.hostIP
            - name: POD_IP
              valueFrom:
                fieldRef:
                  fieldPath: status.podIP
          volumeMounts:
            - name: host-time
              mountPath: /etc/localtime
              readOnly: true
            - mountPath: /var/run/docker.sock
              name: docker-socket
              readOnly: true
            #- mountPath: /bin/docker
             # name: docker-binary
              #readOnly: true
            - mountPath: /bin/kubectl
              name: kubectl-binary
              readOnly: true
            - mountPath: /root/.kube 
              name: kubectl-config-path
EOF
if $PV; then
  cat >> $OUT <<EOF
            - name: {{.name}} 
              mountPath: "/var/jenkins_home"
EOF
fi
cat >> $OUT <<EOF
      volumes:
        - name: host-time
          hostPath:
            path: /etc/localtime
        - name: docker-socket
          hostPath:
            path: /var/run/docker.sock
        #- name: docker-binary
         # hostPath:
          #  path: /usr/local/bin/docker
        - name: kubectl-binary
          hostPath:
            path: {{.kubectl.binary.path}}
        - name: kubectl-config-path
          hostPath:
            path: {{.kubectl.config.path}}
EOF
if $PV; then
  cat >> $OUT <<EOF
        - name: {{.name}} 
          persistentVolumeClaim:
            claimName: {{.name}}-claim 
EOF
fi
if [[ "NGINX" == "${HA}" ]]; then
  cat >> $OUT <<EOF
        - name: nginx-conf
          configMap:
            name: nginx-conf 
EOF
fi
