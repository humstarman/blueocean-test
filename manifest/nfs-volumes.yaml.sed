---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: blueocean-claim
  namespace: {{.namespace}}
  annotations:
    volume.beta.kubernetes.io/storage-class: "managed-nfs-storage"
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 10Gi
