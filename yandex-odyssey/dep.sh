#!/bin/bash
#rm -f ~/.kube/config
#cp "${KUBE03_CONFIG}" ~/.kube/config
set -o pipefail

for i in {1..3}; do
kubectl apply -f - <<EOF
---
apiVersion: v1
kind: Service
metadata:
  name: pg-service-${i}
  labels:
    app.kubernetes.io/name: pg${i}
spec:
  ports:
    - name: pg
      port: 5432
      targetPort: 5432
  selector:
    app.kubernetes.io/name: pg${i}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pg-deployment-${i}
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: pg${i}
  replicas: 1
  template:
    metadata:
      labels:
        app.kubernetes.io/name: pg${i}
    spec:
      containers:
      - name: postgres
        image: docker.io/postgres:14-bullseye
        ports:
        - containerPort: 5432
          name: pg
        env:
        - name: POSTGRES_USER
          value: testadmin
        - name: POSTGRES_PASSWORD
          value: testadmin
        - name: POSTGRES_HOST_AUTH_METHOD
          value: md5
        readinessProbe:
          tcpSocket:
            port: 5432
          initialDelaySeconds: 30
          periodSeconds: 5
          timeoutSeconds: 1
          successThreshold: 2
          failureThreshold: 3
EOF
done

for i in {1..3}; do
	kubectl wait pod -l app.kubernetes.io/name=pg"${i}" --for=condition=Ready --timeout=5m
done


kubectl apply -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: modify-param-in-pg-service
  labels:
    app.kubernetes.io/name: job-test
spec:
  backoffLimit: 15
  activeDeadlineSeconds: 180
  ttlSecondsAfterFinished: 60
  template:
    spec:
      containers:
        - name: install-md5-param
          command:
          - 'bash'
          - '-c'
          - 'PGPASSWORD=testadmin psql --username=testadmin --host=pg-service-1 --command="ALTER SYSTEM SET password_encryption = md5;" &&
            PGPASSWORD=testadmin psql --username=testadmin --host=pg-service-1 --command="SELECT pg_reload_conf();" &&
            PGPASSWORD=testadmin psql --username=testadmin --host=pg-service-2 --command="ALTER SYSTEM SET password_encryption = md5;" &&
            PGPASSWORD=testadmin psql --username=testadmin --host=pg-service-2 --command="SELECT pg_reload_conf();" &&
            PGPASSWORD=testadmin psql --username=testadmin --host=pg-service-3 --command="ALTER SYSTEM SET password_encryption = md5;" &&
            PGPASSWORD=testadmin psql --username=testadmin --host=pg-service-3 --command="SELECT pg_reload_conf();"'
          image: docker.io/library/yandex-odyssey:0.0.10-rc.29
      restartPolicy: Never
      imagePullSecrets:
      - name: "registry-pull-secret"
EOF

kubectl wait job -l app.kubernetes.io/name=job-test --for=condition=Complete --timeout=5m
sleep 70