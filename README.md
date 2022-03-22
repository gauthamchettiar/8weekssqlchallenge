# What's This?
This repository contains Solutions to SQL Problems From [https://8weeksqlchallenge.com/](https://8weeksqlchallenge.com/).

Currently has solutions to:
1. [Dannys Dinner](https://8weeksqlchallenge.com/case-study-1/) - [Solutions](01_dannys_dinner/)
2. [Pizza Runner](https://8weeksqlchallenge.com/case-study-2/) - [Solutions](02_pizza_runner/)

## Preparing Datasets
1. Login to Default Database
    ```bash
    psql postgres
    ```
2. Create Database
    ```sql
    CREATE DATABASE eightweekssqlchallenge;
    ```
3. Create Required Tables
    ```
    psql eightweekssqlchallenge -f 01_dannys_dinner/00-create_table.sql

    psql eightweekssqlchallenge -f 02_pizza_runner/00-create_table.sql
    psql eightweekssqlchallenge -f 02_pizza_runner/00-cleaned_views.sql
    ```

## Logging into Database and Selecting a Schema
1. Login to Database
    ```bash
    psql eightweekssqlchallenge
    ```
2. Select Schema As Per challenge
    ```sql
    SET search_path = dannys_diner;
    SET search_path = pizza_runner;
    ```
