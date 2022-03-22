# [https://8weeksqlchallenge.com/](https://8weeksqlchallenge.com/) Solutions

## Preparing Datasets
1. Login to Default Database
    ```bash
    psql postgres
    ```
2. Create Database
    ```sql
    CREATE DATABASE eightweekschallenge;
    ```
3. Create Required Tables
    ```
    psql eightweekschallenge -f 01_dannys_dinner/00-create_table.sql

    psql eightweekschallenge -f 02_pizza_runner/00-create_table.sql
    psql eightweekschallenge -f 02_pizza_runner/00-cleaned_views.sql
    ```
## Logging into database and select a schema -
1. Login to Database
    ```bash
    psql eightweekschallenge
    ```
2. Select Schema As Per challenge
    ```sql
    SET search_path = dannys_diner;
    SET search_path = pizza_runner;
    ```
