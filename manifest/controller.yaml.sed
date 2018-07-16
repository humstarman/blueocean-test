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
