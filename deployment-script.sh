#!/bin/bash

# Prompt the user for input
echo "Enter the namespace name: "
read NAMESPACE
echo "Enter the database name: "
read DB_NAME
echo "Enter the PostgreSQL user: "
read PGSQL_USER
echo "Enter the PostgreSQL password: "
read -s PGSQL_PASSWORD
echo

# Create the deployment YAML content
echo | kubectl apply -f - << EOF
apiVersion: v1
kind: Namespace
metadata:
  name: $NAMESPACE
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
  namespace: $NAMESPACE
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
---
apiVersion: v1
kind: Secret
metadata:
  name: postgres-secrets
  namespace: $NAMESPACE
type: Opaque
stringData:
  POSTGRES_USER: $PGSQL_USER
  POSTGRES_PASSWORD: $PGSQL_PASSWORD
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
  namespace: $NAMESPACE
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:14
        ports:
        - containerPort: 5432
        env:
        - name: POSTGRES_DB
          value: $DB_NAME
        - name: POSTGRES_USER
          valueFrom:
            secretKeyRef:
              name: postgres-secrets
              key: POSTGRES_USER
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secrets
              key: POSTGRES_PASSWORD
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: postgres-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: postgres-service
  namespace: $NAMESPACE
spec:
  selector:
    app: postgres
  ports:
    - protocol: TCP
      port: 5432
      targetPort: 5432
EOF

# Wait for the deployment to be ready
kubectl rollout status deployment/postgres -n $NAMESPACE

# Define the pod name
POD_NAME=$(kubectl get pods -n $NAMESPACE -l app=postgres -o jsonpath="{.items[0].metadata.name}")

# Wait for PostgreSQL to be ready
kubectl exec -it $POD_NAME -n $NAMESPACE -- sh -c 'until pg_isready -h localhost -U $POSTGRES_USER; do echo waiting for postgres; sleep 2; done'

# Create the table if it does not exist
#kubectl exec -it $POD_NAME -n $NAMESPACE -- psql -U $PGSQL_USER -d $DB_NAME -c "CREATE TABLE IF NOT EXISTS my_table (column1 TEXT, column2 TEXT);"

# Create the table if it does not exist and insert 10 random values
for i in {1..10}; do
  kubectl exec -it $POD_NAME -n $NAMESPACE -- sh -c "
    psql -U $PGSQL_USER -d $DB_NAME -c \"CREATE TABLE IF NOT EXISTS my_table (column1 TEXT, column2 TEXT);\"
    RANDOM_VALUE1=\$(openssl rand -hex 8)
    RANDOM_VALUE2=\$(openssl rand -hex 8)
    psql -U $PGSQL_USER -d $DB_NAME -c \"INSERT INTO my_table (column1, column2) VALUES ('\$RANDOM_VALUE1', '\$RANDOM_VALUE2');\"
"
done
echo ""
echo "Inserted 10 random values into $DB_NAME.my_table"
echo ""
# Show the values in the table
kubectl exec -it $POD_NAME -n $NAMESPACE -- psql -U $PGSQL_USER -d $DB_NAME -c "SELECT * FROM my_table;"

