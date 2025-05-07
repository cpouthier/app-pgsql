# 🐘 PostgreSQL Deployment Script on Kubernetes

This script automates the deployment of a PostgreSQL instance in a Kubernetes cluster.

It:
- Prompts for user input (namespace, DB name, credentials)
- Deploys Kubernetes resources (Namespace, PVC, Secret, Deployment, Service)
- Waits for readiness
- Creates a table and inserts 10 rows of random data
- Displays the table content

---

## 📦 Prerequisites

- A running Kubernetes cluster
- `kubectl` installed and configured
- `openssl` installed (for generating random values)
- Permissions to create namespaces and deploy resources

---

## 🚀 Usage

1. Make the script executable:

   ```bash
   chmod +x deploy_postgres.sh
   ```

2. Run it:

   ```bash
   ./deploy_postgres.sh
   ```

3. Follow the prompts:
   - Namespace name
   - Database name
   - PostgreSQL username and password

---

## 🛠️ What It Does

### 1. Prompt for Input
```bash
read NAMESPACE
read DB_NAME
read PGSQL_USER
read -s PGSQL_PASSWORD
```

### 2. Create Kubernetes Resources
- **Namespace**
- **PersistentVolumeClaim** for storage
- **Secret** to store credentials
- **Deployment** with PostgreSQL container
- **Service** to expose the DB internally

All are applied using `kubectl apply -f - <<EOF ... EOF`.

### 3. Wait for Deployment Readiness
```bash
kubectl rollout status deployment/postgres -n $NAMESPACE
```

### 4. Wait for PostgreSQL to Be Ready
```bash
pg_isready -h localhost -U $POSTGRES_USER
```

### 5. Create Table and Insert Data
- Table: `my_table(column1 TEXT, column2 TEXT)`
- Random values generated with `openssl rand -hex 8`
- 10 rows inserted

### 6. Display the Table
```bash
SELECT * FROM my_table;
```

---

## 📄 Sample Output

```
Inserted 10 random values into my_database.my_table

 column1  | column2
----------+----------
 a1b2c3d4 | e5f6g7h8
 ...
```

---

## 🧹 Cleanup

To delete all the created resources:

```bash
kubectl delete namespace <your-namespace>
```

---

## 📝 Notes

- PostgreSQL image used: `postgres:14`
- You can change the version or modify the SQL logic as needed
- The table creation and inserts are re-run each time you execute the script

---

## 📬 Contributing

Pull requests welcome! Feel free to open issues for bugs or suggestions.
