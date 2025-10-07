# EU Pizza System

Relational database and small Java CLI for a pizza shop.  
The repo contains: schema, sample data, business logic (triggers + stored procedures), pricing/label views, and SQL reports.

---

## 1) Repository layout

```
sql/
  01_schema.sql        # tables, PK/FK, indexes (DDL only)
  02_sample_data.sql   # sample data (ingredients, menu, customers, drivers, >=20 orders)
  03_logic.sql         # triggers + procedures (place_order, set_delivery_status)
  04_views.sql         # views (dynamic pricing, labels, menu with price)
  05_reports.sql       # reporting queries (ready to run)
app/
  pom.xml
  src/main/java/com/pizza/   # CLI application
  src/main/resources/db.properties.example
```

---

## 2) How to load the database

**Option A – step by step**
```bash
mysql -u root -p < sql/01_schema.sql
mysql -u root -p < sql/02_sample_data.sql
mysql -u root -p < sql/03_logic.sql
mysql -u root -p < sql/04_views.sql
mysql -u root -p < sql/05_reports.sql
```

**Option B – full dump (optional)**
```bash
mysql -u root -p < sql/99_full_dump.sql
```

---

## 3) Run the CLI (Java 17, Maven)

1) Create `app/src/main/resources/db.properties` from the example:
```properties
db.url=jdbc:mysql://localhost:3306/pizza_ordering?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true
db.user=YOUR_USER
db.pass=YOUR_PASSWORD
```
2) Build & run:
```bash
mvn -f app/pom.xml clean package
mvn -f app/pom.xml exec:java -Dexec.mainClass="com.pizza.Main"
```

---

## 4) Quick demo flow

1. **Show menu** – option `1` in CLI.  
2. **Add to cart** – option `2`, e.g. `menu_item_id=1`, `qty=2` then a drink.  
3. **Place order** – option `3`, optionally enter `WELCOME10`.  
4. **Undelivered report** – option `6`.  
5. **Change delivery status** – option `4` → `OUT_FOR_DELIVERY` then `DELIVERED`.  
6. **Top 3 pizzas (30d)** – option `5`.

---

## 5) Notes

- I used Polish in sample data (bcs I am Polish and its Polish pizzeria).  

