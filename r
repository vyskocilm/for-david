#!/bin/bash

set -x
set -e

die () {
    echo "${@}" >&2
    exit 1
}

psql -f 01-initdb.sql

export CONNECTION_URL=${CONNECTION_URL:-pgsql:/mvyskocil@mvyskocil}
export INPUT_FILE=${INPUT_FILE:-"example-products.csv"}
./hw.q

## Sanity test

if [[ "${INPUT_FILE}" != "example-products.csv" ]]; then
    exit 0;
fi

psql -c "copy (SELECT cust_num, cust_name FROM customers ORDER BY cust_num) To STDOUT WITH CSV DELIMITER ',';" > t/customers.csv
cmp t/customers.t t/customers.csv || die "List of customers differs"
psql -c "copy (SELECT cust_id, filename, part_code, description, delivery_date, order_reference FROM customer_inventory ORDER BY order_reference) To STDOUT WITH CSV DELIMITER ',';" > t/customer_inventory.csv
cmp t/customer_inventory.t t/customer_inventory.csv || die "List of customer_inventory differs"
