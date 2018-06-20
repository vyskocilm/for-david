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
        /*

        MVY: I gave up on how to solve the duplicates in Qore This is NOT nice,
            because it means a transaction per line and SLOOW. However I did not
            find a way how to solve the duplicated while having constraints in DB
            when using InboundTableMapper

            with using "upsert" : True I had issued with cust_id

            Alternative wouls be to track it on application level as I already have
            cust_nmbr_map, however this is NOT what I wanted to do.
            Plus I have learned exception handling in qore :-)

        */
        try {
            hash ret = customers_mapper.insertRow (csv.getRecord ());
            customers.commit ();
            cust_nmbr_map {csv."CustNmbr"} = ret."cust_id";
        }
        catch (exc) {
            /*
            MVY: I assume error is duplicate error, but did not implemented checks

            This is one time script and SQL error would be reported via customer_inventory_mapper
            anyway

            ... I said this is not the best approach I can have, normally I would do
            INSERT ... (cust_num, cust_name) VALUES (); but can't find the way how to skip cust_id
            */

            /*
            printf ("exc: err=%s, desc=%s, arg=%s",
                    exc.err,
                    exc.desc,
                    exc.arg);
            */
            customers_mapper.rollback ();
        }

        /* add entry to customer_inventory table */
        customer_inventory_mapper.insertRow (csv.getRecord ());
    }
    customers.commit ();
    customer_inventory.commit ();
}

string connection_url = getenv ("CONNECTION_URL");
string filename = getenv ("INPUT_FILE");

import_phones (connection_url, filename);
