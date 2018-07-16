LOCAL_REGISTRY="192.168.100.167:5000"
IMAGE_NAME="blueocean"
IMAGE_TAG="v1"
ANSIBLE_GROUP="all"
KUBE_API_SECURE_PORT="6443"
KUBE_API_INSECURE_PORT="8080"
KUBECTL_BINARY_PATH="/usr/local/bin/kubectl"
KUBECTL_CONFIG_PATH="/root/.kube"
NAME="blueocean"
NAMESPACE="gitlab"
HA_METHOD="vip"
#HA_METHOD="nigix"
PV="false"
OUTPUT="./manifest/controller.yaml.sed"

IMAGE=${LOCAL_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
ARGS="-a ${HA_METHOD} -o ${OUTPUT}"
ifeq (${PV},"true")
ARGS+=" -p"
endif
ifeq (${HA_METHOD},"nginx")
MASTER_IP_1=1
MASTER_IP_2=2
MASTER_IP_3=3
endif

test:
ifeq (${PV},"true")
	@echo okay
else
	@echo ${ARGS}
endif

build:
	@docker build -t ${IMAGE} .

push:
	@docker push ${IMAGE}

pull:
	-@ansible ${ANSIBLE_GROUP} -m shell -a "docker pull ${IMAGE}"

sed:
	@yes | cp ./manifest/namespace.yaml.sed ./manifest/namespace.yaml
	@yes | cp ./manifest/service.yaml.sed ./manifest/service.yaml
	@yes | cp ./manifest/ingress.yaml.sed ./manifest/ingress.yaml
	@sed -i s?"{{.namespace}}"?"${NAMESPACE}"?g ./manifest/namespace.yaml
	@sed -i s?"{{.name}}"?"${NAME}"?g ./manifest/service.yaml
	@sed -i s?"{{.namespace}}"?"${NAMESPACE}"?g ./manifest/service.yaml
	@sed -i s?"{{.name}}"?"${NAME}"?g ./manifest/ingress.yaml
	@sed -i s?"{{.namespace}}"?"${NAMESPACE}"?g ./manifest/ingress.yaml
ifeq (${HA_METHOD},"nginx")
	@yes | cp ./manifest/configmap.yaml.sed ./manifest/configmap.yaml
	@sed -i s?"{{.namespace}}"?"${NAMESPACE}"?g ./manifest/configmap.yaml
	@sed -i s?"{{.kube-apiserver.secure.port}}"?"${KUBE_API_SECURE_PORT}"?g ./manifest/configmap.yaml
	@sed -i s?"{{.master.ip.1}}"?"${MASTER_IP_1}"?g ./manifest/configmap.yaml
	@sed -i s?"{{.master.ip.2}}"?"${MASTER_IP_2}"?g ./manifest/configmap.yaml
	@sed -i s?"{{.master.ip.3}}"?"${MASTER_IP_3}"?g ./manifest/configmap.yaml
endif
	@./scripts/mk-template.sh "${ARGS}"
	@yes | cp ./manifest/controller.yaml.sed ./manifest/controller.yaml
	@sed -i s?"{{.name}}"?"${NAME}"?g ./manifest/controller.yaml
	@sed -i s?"{{.namespace}}"?"${NAMESPACE}"?g ./manifest/controller.yaml
	@sed -i s?"{{.kube-apiserver.secure.port}}"?"${KUBE_API_SECURE_PORT}"?g ./manifest/controller.yaml
	@sed -i s?"{{.kube-apiserver.insecure.port}}"?"${KUBE_API_INSECURE_PORT}"?g ./manifest/controller.yaml
	@sed -i s?"{{.image}}"?"${IMAGE}"?g ./manifest/controller.yaml
	@sed -i s?"{{.kubectl.binary.path}}"?"${KUBECTL_BINARY_PATH}"?g ./manifest/controller.yaml
	@sed -i s?"{{.kubectl.config.path}}"?"${KUBECTL_CONFIG_PATH}"?g ./manifest/controller.yaml

deploy:
	-@kubectl create -f ./manifest/namespace.yaml
	-@kubectl create -f ./manifest/service.yaml
	-@kubectl create -f ./manifest/ingress.yaml
ifeq (${HA_METHOD},"nginx")
	-@kubectl create -f ./manifest/configmap.yaml
endif
	@kubectl create -f ./manifest/controller.yaml

all: build push pull sed deploy

clean:
	-@kubectl delete -f ./manifest/service.yaml
	-@kubectl delete -f ./manifest/ingress.yaml
	-@kubectl delete -f ./manifest/configmap.yaml
	-@kubectl delete -f ./manifest/controller.yaml
	-@rm -f ./manifest/service.yaml
	-@rm -f ./manifest/ingress.yaml
	-@rm -f ./manifest/configmap.yaml
	-@rm -f ./manifest/controller.yaml

refresh:
	@kubectl delete -f ./manifest/configmap.yaml
	@kubectl create -f ./manifest/configmap.yaml
