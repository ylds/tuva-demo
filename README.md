# Oncology Cost & Prevalence Analysis (Tuva Project Demo)

## 🧰 What does this project do?

This project extends **The Tuva Project dbt demo** to analyze **cancer prevalence and cost drivers** using synthetic claims data.

Using institutional oncology-related claims, this analysis:
- Identifies patients with cancer
- Measures prevalence across cancer types
- Analyzes **total paid amount** and **utilization patterns**
- Breaks down costs by **care setting** (Inpatient, Outpatient, etc.)
- Highlights **top cost drivers by cancer type**

The project follows dbt best practices using a **Staging → Intermediate → Mart** architecture.

## 🧱 Project Structure

```text
models/
├── staging/
├── intermediate/
│   ├── int_oncology_claims.sql
│   ├── int_oncology_costs.sql
│   └── int_oncology_patients.sql
└── marts/
    └── fct_oncology_cost_by_cancer_type.sql
    └── fct_oncology_costs.sql
```
---

## 🔬 Methodology

### Cancer Definition
A patient was classified as having cancer if they had at least one claim containing:
- Oncology-related diagnosis codes  
- Oncology-related procedure or revenue center codes  
(as provided in the Tuva Project synthetic dataset)

### Cost Definition
- Only **paid amounts** were used for cost analysis
- Costs were aggregated at the **claim level** to avoid double-counting line items
- Analysis focused on **institutional claims** only

### Care Setting Classification
Care setting was derived using a combination of:
- **Type of Bill (TOB)** codes  
- **Revenue Center Codes**, with priority given to Emergency Department codes

### Data Ambiguities & Assumptions
- Claims with missing or ambiguous bill types were categorized as `Unknown`
- Emergency Department claims were identified primarily via revenue center codes
- Cancer type assignment was done at the **patient level**, not per claim

---

## 📊 Key Findings (Executive Summary)

### 📈 Overall Cancer Population (data range: 2016~2018)
- 🧾 **1,000** oncology-related claim lines  
- 📄 **215** distinct claims  
- 👥 **79** distinct patients  
- 💰 **$218,109.96** total cancer-related paid amount  

---

### 🏥 Cost by Care Setting

| Care Setting | Claims | Patients | Total Paid | Avg Paid / Claim |
|-------------|-------:|---------:|-----------:|-----------------:|
| Inpatient | 9 | 9 | $130,830.95 | $14,536.77 |
| Outpatient | 173 | 67 | $85,417.38 | $493.74 |
| Emergency Department | 4 | 4 | N/A | N/A |
| Other Institutional | 1 | 1 | $331.79 | $331.79 |
| Unknown | 32 | 17 | $1,529.84 | $47.81 |

**Insight:**  
Although outpatient claims dominate volume, **inpatient care accounts for the majority of spend**, indicating that severe episodes drive costs.

---

### 🧬 Top Cost Drivers by Cancer Type & Care Setting

**High-Cost Drivers**
- 🩸 **Hematologic cancers (Inpatient)**  
  - $56K total paid, highest average cost per claim
- 🌐 **Metastatic / Secondary cancers**  
  - High costs across both inpatient and outpatient settings
- 🧠 **Other solid tumors (Inpatient)**  
  - Fewer claims but high per-claim cost

**High-Volume, Lower-Cost Cancers**
- 🎗️ **Prostate cancer (Outpatient)**  
- 🎀 **Breast cancer (Outpatient)**  

These represent chronic, treatment-heavy conditions with **high utilization but lower cost per encounter**.

---

## 🧠 AI Usage Log

AI tools were used to **accelerate development**, including:
- Drafting dbt SQL model templates
- Generating initial care-setting classification logic
- Structuring README documentation and executive summaries

### Corrections & Human Oversight
- Care setting logic was **manually refined** after validating actual bill type and revenue center distributions
- Aggregation grain was corrected to avoid double-counting
- AI-generated assumptions were validated against observed data patterns

AI was used as a productivity aid, with **final logic and interpretations validated manually**.


