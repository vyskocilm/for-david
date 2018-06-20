#!/usr/bin/qore

%new-style
%enable-all-warnings
%require-types
%enable-all-warnings

%requires CsvUtil
%requires TableMapper
%requires SqlUtil

sub import_phones (string connection_url, string filename)
{
    hash opts = {
        "date_format" : "DD/MM/YYYY",
        "encoding" : "ASCII",
        "header_names" : True,
        "header_lines" : 1,
        "quote" : '"',
        "separator": ',',
        "verify_columns" : True,
    };
    CsvUtil::CsvFileIterator csv (filename, opts);

    Table customers (
        connection_url, "customers", {});
    Table customer_inventory (
        connection_url, "customer_inventory", {});

    /*maps CustNmbr to cust_id*/
    hash cust_nmbr_map;

    hash customers_mapping = {
        "cust_id" : ("sequence" : "customers_id"),
        "cust_num" : "CustNmbr",
        "cust_name" : "CustomerName",
    };

    hash customer_inventory_mapping = {
        "inventory_id" : ("sequence" : "customer_inventory_id"),
        "cust_id": ("code": int sub (nothing x, hash rec) { return cust_nmbr_map{rec."CustNmbr"}; }),
        "filename" : ("constant" : filename),
        "part_code" : "PartNmbr",
        "description" : "Description",
        "delivery_date" : ("name" : "Deldate", "date_format": "DD/MM/YYYY"),
        "order_reference" : "Orderref",
    };

    InboundTableMapper customers_mapper(
        customers,
        customers_mapping,
    );
    InboundTableMapper customer_inventory_mapper(
        customer_inventory,
        customer_inventory_mapping,
    );

    while (csv.next ()) {
        if (!cust_nmbr_map {csv."CustNmbr"}) {
            hash ret = customers_mapper.insertRow (csv.getRecord ());
            cust_nmbr_map {csv."CustNmbr"} = ret."cust_id";
            customers.commit ();
        }

        customer_inventory_mapper.insertRow (csv.getRecord ());
    }
    customers.commit ();
    customer_inventory.commit ();
}

string connection_url = getenv ("CONNECTION_URL");
string filename = getenv ("INPUT_FILE");

import_phones (connection_url, filename);
