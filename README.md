# Port-Capacity-Analysis-University-Project-

This repository contains the code and report for a harbour operations simulation project using a Discrete Event Simulation (DES) model. The project was conducted as part of a university research assignment to analyze the current and future capacity of Port Blair harbour. The study was prepared by:

Kavish Sharma

---

## Project Overview
The project uses a DES model to simulate the operations of Port Blair’s harbour under both **Business-as-Usual (BAU)** and **Future Scenarios (FS)**. The simulation answers key questions about the harbour’s ability to handle current and increased ship arrivals, and whether upgrades to the lock or unloading processes are required.  

Historical data on **ship interarrival, locking, and unloading times** were analyzed to fit appropriate statistical distributions. The simulation model was validated using **Verification, Validation, Accreditation & Acceptance (VV&A)**, and the results were used to answer the research questions reliably.

---

## Key Questions Addressed
1. Is the harbour’s capacity sufficient to handle current demand?  
2. Would upgrading the lock or unloading processes improve efficiency under current conditions?  
3. If ship arrivals increase by 10% in the future, will the harbour require improvements to handle the additional traffic?  

**Summary of Findings:**  
- The harbour can handle current demand without issues.  
- Process upgrades are unnecessary under current conditions.  
- Even with a 10% increase in arrivals, the harbour can accommodate ships without requiring improvements.

---

## Methodology
- Historical data was cleaned and analyzed to identify **distribution types and parameters** using **histograms and QQ-plots**.  
- A DES model was implemented with **two FIFO queues** (sea queue and harbour queue) and servers for **lock and dock operations**.  
- The simulation was run for **200 realizations**, excluding burn-in periods calculated using **Welch’s method**.  
- **Time average** and **ensemble average** metrics were used to analyze system performance.

---

## Repository Structure
The repository contains three main branches:

### main
Contains the full project report, simulation functions, the harness file, and figures generated from the simulations. Key components include:

- `/functions` – Python functions implementing the simulation logic, with full comments.
- `/harness` – Harness file to run the simulation over multiple seeds.
- `/figures` – Plots and figures used to identify distributions, estimate parameters, and answer research questions.
- Full report with methodology, results, and conclusions.

### data-file
Contains simulation results for 200 seeds under current traffic conditions. Each seed folder includes:

- `entity file` – Features: `id`, `arrival_time`, `start_service_times`, `completion_time`.
- `state file` – Features: `time`, `event_id`, `event_type`, `timing`, `length_event_list`, `length_queue1`, `length_queue2`, `in_service1`, `in_service2`.
- `weighted average file` – Weighted averages over 80 hours showing `time`, `total_ships`, and `harbour_ships`.

### data-file-10percent
Same as `data-file`, but with a **10% increase in ship arrivals** to simulate future scenario traffic. Structure and files are identical, allowing comparison with current traffic results.
"""

# Write to README.md
with open("README.md", "w") as file:
    file.write(readme_content)

print("README.md file has been created successfully.")
