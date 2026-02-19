# ecommerce-sql-product-analytics
End-to-end E-commerce Customer &amp; Product Analytics project using SQL on ~1M transactions.

# 📊 E-Commerce Customer & Product Analytics (SQL Project)

## 🚀 Project Overview

This project analyzes ~1 million e-commerce transaction records (2009–2011) to uncover insights related to:

- Revenue drivers  
- Customer retention  
- Product performance  
- Purchase behavior  
- Revenue concentration  
- Customer segmentation  

The analysis was performed entirely using **MySQL**, leveraging advanced SQL concepts such as CTEs and window functions.

---

## 📂 Dataset Details

- **Dataset:** Online Retail II  
- **Period Covered:** 2009–2011  
- **Total Rows:** ~1,000,000 transactions  
- **Customers:** ~4,000+  
- **Products:** ~4,000+ SKUs  
- **Data Type:** Invoice-level transactional data  

### Key Fields Used:
- `customer_id`
- `invoice_no`
- `invoice_date`
- `quantity`
- `unit_price`
- Derived: `revenue = quantity × unit_price`

---

## 🧹 Data Cleaning & Preparation

Before performing analysis:

- Removed cancelled invoices for revenue calculations  
- Handled negative quantities (returns) separately  
- Removed invalid / NULL customer IDs  
- Created clean analytical dataset (`retail_clean`)  
- Maintained raw dataset (`retail_transactions`) for return analysis  

---

## 📈 Business Questions Answered

### 1️⃣ Top Revenue-Generating Products  
Identified top 10 SKUs driving overall revenue.

### 2️⃣ Monthly Revenue & Growth Analysis  
- Monthly revenue trend  
- Active customers  
- ARPU (Average Revenue Per User)  
- Month-over-month growth  

### 3️⃣ Top Customers by Lifetime Value  
- Total revenue per customer  
- Average Order Value (AOV)  
- Revenue ranking  

### 4️⃣ Revenue Concentration (Pareto Analysis)  
- % of products contributing to 80% of total revenue  
- Identified revenue dependency concentration  

### 5️⃣ Repeat Purchase Rate  
Calculated % of customers who made more than one purchase.

### 6️⃣ Purchase Frequency Analysis  
Measured average days between consecutive orders.

### 7️⃣ Return Rate Analysis  
- Order-level return rate  
- Product-level return rate  
- Identified operational anomalies  

### 8️⃣ Cohort Retention Analysis  
- Monthly cohort tracking  
- Customer retention rate by month  
- Identified drop-off pattern after first purchase  

### 9️⃣ RFM Segmentation  
Segmented customers into:

- Champions  
- Loyal Customers  
- Potential  
- At Risk  
- Hibernating  

Analyzed revenue contribution by segment.

---

## 🧠 Key Insights

- Revenue is concentrated among a small percentage of products (Pareto effect observed).  
- Top customer segment contributes disproportionately to total revenue.  
- Month 1 retention drops significantly, indicating transactional buying behavior.  
- Repeat purchase rate suggests moderate customer stickiness.  
- Average repurchase cycle reveals customer buying frequency patterns.  

---

## 🛠 SQL Concepts Used

- Common Table Expressions (CTEs)  
- Window Functions (`LAG`, `NTILE`, `SUM() OVER`)  
- Cohort Analysis  
- RFM Scoring  
- Cumulative Revenue Calculation  
- Conditional Aggregation  
- Ranking Functions (`DENSE_RANK`)  

---

## 🧰 Tools Used

- MySQL  
- GitHub  

---

## 🎯 Project Objective

To demonstrate the practical application of SQL in solving real-world business analytics problems including:

- Revenue optimization  
- Customer retention analysis  
- Product performance evaluation  
- Customer segmentation  

---

## 🚀 Future Enhancements

- Power BI dashboard integration  
- Advanced Customer Lifetime Value modeling  
- Predictive churn analysis  
